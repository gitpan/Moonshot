package Moonshot::Connection;

#
# $Revision: 1.4 $
# $Author: psionic $
# $Date: 2003/04/18 15:55:35 $
#

=head1 NAME

Moonshot::Connection - Interface to Moonshot Jukebox protoocol

=head1 SYNOPSIS

$juke = new Moonshot::Connection( Server => "jukebox" );
$juke->connect();
$juke->add($album, $track);
print $juke->get_status();

=head1 DESCRIPTION

This module handles the client-side communication with the Moonshot juke daemon.

=head1 METHODS

=over 4

=cut

#-------------------------------------------------------------------------------

use Socket;
use IO::Select;
use Symbol;
use Carp;
use strict;
use vars qw($DEBUG);

=pod

=item Moonshot::Connecton-E<gt>new()

Creates a new Moonshot Jukebox connectio and tries to connect to it.

=cut

sub new {
   my $proto = shift;
   my $self = {
		_port 		=> 8008,
		_connected	=> 0,
		_server		=> "localhost",
		_queue		=> [],
		_buffer		=> "",
	       };
   
   bless $self, $proto;

   if (@_) {
      my (%arg) = @_;

      $self->{_server} = $arg{'Server'} if (defined $arg{'Server'});
      $self->{_port} = $arg{'Port'} if (defined $arg{'Port'});
      $DEBUG = $arg{'Debug'} if (defined $arg{'Debug'});
   }

   return $self;
}

=pod

=item $juk-E<gt>connect()

Connect to the Moonshot jukebox server

=cut 

sub connect {
   my $self = shift;
   my ($host,$port,$sock);


   if (@_) {
      my (%arg) = @_;
      $self->server($arg{'Server'}) if (defined $arg{'Server'});
      $self->port($arg{'Port'}) if (defined $arg{'Port'});
   }

   $sock = Symbol::gensym();
   unless (socket($sock,PF_INET,SOCK_STREAM,getprotobyname('tcp'))) {
      carp("Unable to create a new socket: $!");
      return 0;
   }

   if (connect($sock,sockaddr_in($self->port(), inet_aton($self->server)))) {
      $self->{'_socket'} = $sock;
      $self->{'_connected'} = 1;
   } else {
      carp(sprintf("Unable to connect to %s:%s!", $self->server, $self->port));
      return 0;
   }

   print STDERR "Connecting!!!\n";
   $self->{_select} = new IO::Select($self->{_socket});

   #ignore the "+OK <wecome message>" 
   $self->enqueue("CONNECT");
   $self->cycle(); 

   $self->update();

   return 1;
}

=pod

=item $juke-E<gt>port( [ new port ] )

If you specify a new port, this sets the port on which to connect.
This method returns the current port.

=cut

sub port {
   my $self = shift;
   if ($#_ == 1) { $self->{_port} = shift; }
   return $self->{_port};
}

=pod

=item $juke-E<gt>server( [ $server ] )

If you specify a new server, this sets the server on which to connect.
This method returns the current server hostname.

=cut

sub server {
   my $self = shift;
   if ($#_ == 1) { 
      my $newserv = shift;
      print STDERR "Setting new server: $newserv\n" if ($DEBUG);
      $self->{_server} = $newserv; 
   }
   return $self->{_server};
}

=pod

=item $juke-E<gt>add_album($album [ , $track ])

Add an album or a track to the playlist. Takes album ID and track IDs.

=cut

sub add_album {
   my $self = shift;

   my ($album) = @_;
   if ($album !~ m/^[0-9]+$/) {
      print STDERR "add_album() -> given album isn't a number. You tried: \"$album\"\n";
      return;
   }

   #add an album to the playlist, send the command
   $self->enqueue("ADD","-nothing-");
   $self->send_raw("ADD ALBUM $album")
}

sub add_track {
   my $self = shift;

   my ($album,$track) = @_;
}

##
# enqueue a command so we can parse it depending on the
# type of data is coming from the server
##
sub enqueue {
   my $self = shift;
   my ($cmd,$args) = @_;

   #print STDERR "Pushing [$cmd, $args] onto queue\n" if ($DEBUG);
   push(@{$self->{_queue}}, ["$cmd", "$args"]);
}

##
# Returns 1 if the queue is empty, 0 otherwise
#
##
sub queueisempty {
   my $self = shift;

   return 1 if (scalar(@{$self->{_queue}}) == 0);
   return 0;
}

##
# Wrapper to send data and also enqueue it
#
##
sub sendcmd {
   my $self = shift;
   my ($cmd,$args) = @_;

   $self->enqueue($cmd,$args);
   if ($args ne '') { $self->send_raw("$cmd $args"); }
   else { $self->send_raw("$cmd"); }
}

##
# Perform one cycle of reading up to a +OK or -ERR
# If there are things in the command queue, read until an +OK is given
# and pass the data to the handler.
##
sub cycle {
   my $self = shift;

   my $len = @{$self->{_queue}};
   my $dataref = $self->read();
   my $cmd = shift(@{$self->{_queue}});

   $self->parse($cmd,$dataref);
}

sub read {
   my $self = shift;
   my $sel = $self->{_select};
   my ($data, $buffer) = ("","");

   $buffer = $self->{_buffer};
   $self->{_buffer} = ''; #clear the old buffer

   #If our old buffer has another chunk of data, use it instead of 
   while ($buffer !~ m/\+OK/) {
      if ($buffer =~ m/-ERR/) {
	 print STDERR "Error received!\n";
	 return $buffer;
      }
      my ($ready) = $self->{_select}->can_read(1); #Wait for data for a sec...
      if ($ready) {
	 recv($ready,$data,8192,0);
	 $buffer .= $data;
      }
   }

   ($buffer, $self->{_buffer}) = split(/\+OK\n/,$buffer,2);
   return $buffer;
}

sub parse {
   my $self = shift;
   my ($cmd,$data) = @_;
   my $args;
   #$data = ${$data};
   ($cmd,$args) = @{$cmd};

   #print STDERR "$cmd ($cmd $args): " . length($data) . "\n";
   #ignore ^(ADD|MOVE|REMOVE|CLEAR|SHUFFLE|PAUSE|PLAY|SAVE|LOAD)$/) 
   if ($cmd =~ m/^ALBUM$/i) {
      $self->parse_albums($data);
   } elsif ($cmd =~ m/^TRACK$/i) {
      $self->parse_tracks($data);
   } elsif ($cmd =~ m/^STATUS$/i) {
      $self->parse_status($data);
   } elsif ($cmd =~ m/^LIST$/i) {
      $self->parse_list($data);
   } elsif ($cmd =~ m/^SETUP$/i) {
      $self->parse_setup($data);
   }
}

##
# Send data across the socket
##
sub send_raw {
   my $self = shift;
   my $data = shift;

   chomp($data); $data .= "\n";
   send($self->{_socket}, $data, 0);
}

##
# Make sure we're updated.
#
##
sub update {
   my $self = shift;

   $self->update_tracklist();
   $self->update_playlist();
}

##
# Update the tracklist
#
##
sub update_tracklist {
   my $self = shift;

   #Update the album list
   $self->enqueue("ALBUM");
   $self->send_raw("ALBUM");

   #Update the track list
   $self->enqueue("TRACK");
   $self->send_raw("TRACK");
   $self->cycle();
   $self->cycle();
}

##
# Update the playlist
#
##
sub update_playlist {
   my $self = shift;

   $self->enqueue("LIST");
   $self->send_raw("LIST");
   $self->cycle();

   $self->setflag("playlist_changed" => 1);
}

"Jordan Sissel E<lt>psionic\@csh.rit.eduE<gt>"
