package Moonshot::Jukebox;

#
# $Revision: 1.3 $
# $Author: psionic $
# $Date: 2003/04/18 22:22:59 $
#

=head1 NAME

Moonshot::Jukebox - Keeps track of available albums and titles on the jukebox

=head1 SYNOPSIS

=head1 DESCRIPTION

=over 4

=cut

#-------------------------------------------------------------------------------

use Moonshot::Album;
use Moonshot::Track;
use Moonshot::Connection;

use vars (@ISA);

@ISA = qw(Moonshot::Connection);

=item Moonshot::Jukebox-E<gt>new()

Create a new jukebox

=cut

sub new {
   my $proto = shift;

   my $self = new Moonshot::Connection(@_);

   $self->{_albums} = {};
   $self->{_tracks} = {};
   $self->{_playlist} = [];

   bless $self, $proto;

   return $self;
}

sub parse_albums {
   my $self = shift;
   my $data = shift;

   print STDERR "parse_albums()\n";
   foreach my $album (split("\n",$data)) {
      chomp($album);
      $album =~ m/^([0-9]+)\s		# Album ID
		   \"(.*)\"\s		# Album name
		   \"(.*)\"\s		# Artist
		   ([0-9]+)\s		# Length
		   ([0-9]+)		# tracks
		   $/x;
      #print STDERR "Album: ($3) $2 (Length: $4 seconds)\n";
      $self->{_albums}->{$1} = new Moonshot::Album( 'ID' => $1, "Title" => $2, "Artist" => $3, "Length" => $4, "Tracks" => $5 );
   }
}

sub parse_tracks {
   my $self = shift;
   my $data = shift;

   print STDERR "parse_tracks()\n";
   foreach my $track (split("\n",$data)) {
      $track =~ m/^([0-9]+)\s		# Album ID
		   ([0-9]+)\s		# Track number
		   \"(.*)\"\s		# Album name
		   \"(.*)\"\s		# track title
		   \"(.*)\"\s		# Artist
		   ([0-9]+)		# Length
		   $/x;
      $self->{_tracks}->{"$1.$2"} = new Moonshot::Track('AlbumID' => $1, "Track" => $2, "AlbumTitle" => $3, "TrackTitle" => $4, "Artist" => $5, "Length" => $6);
   }
}

sub parse_setup {
   my $self = shift;

   print STDERR "parse_setup()\n";

   @_ = split(" ",lc(shift()));
   while (scalar(@_)) {
      my ($key,$val) = (shift(),shift());
      $self->{"_$key"} = $val;
   }
}

sub parse_status {
   my $self = shift;

   my $data = lc(shift());
   chomp($data);
   @_ = split(" ",$data);
   my ($state,$index,$clock,$update) = @_;

   $self->{_state} = { "state" => $state, 
		       "index" => $index, 
		       "clock" => $clock };
   $self->update_playlist() if ($update =~ m/playlist/);
}

sub parse_list {
   my $self = shift;
   my $data = shift;

   print STDERR "parse_list()\n";
   #Wipe the list...
   $self->{_playlist} = [];
   foreach my $track (split("\n",$data)) {
      $track =~ m/^([0-9]+)\s		# Album ID
		   ([0-9]+)\s		# Track number
		   \"(.*)\"\s		# Album name
		   \"(.*)\"\s		# track title
		   \"(.*)\"\s		# Artist
		   ([0-9]+)		# Length
		   $/x;
      push(@{$self->{_playlist}}, $self->{_tracks}->{"$1.$2"});
   }

   print STDERR "Number of tracks in the playlist: " . scalar(@{$self->{_playlist}}) . " / " . scalar(keys(%{$self->{_tracks}})) . "\n";
   foreach (@{$self->{_playlist}}) {
      print $_->as_string() . "\n";
      #print STDERR "Type: " . (ref($_) || $_) . "\n";
   }
}

=pod

=item $juke->add_album( [ album id ] )
Add an entire album to the playlist. Takes album ID.

=cut

sub add_album {
   my $self = shift;

   my ($id) = @_;
   if ($id !~ m/^[0-9]+$/) {
      print STDERR "add_album() -> given album isn't a number. You tried: \"$id\"\n";
      return;
   }

   #verify that this is a valid album
   whine("Album ID $id is not valid") if (! defined($album{$id}));


   #add an album to the playlist, send the command
   $self->enqueue("ADD","ALBUM $id");
   $self->send_raw("ADD ALBUM $id")
}

sub add_track {
   my $self = shift;

   my ($album,$track) = @_;
   if ($album !~ m/^[0-9]+$/) {
      print STDERR "add_track() -> given album isn't a number. You tried: \"$album\"\n";
      return;
   }
   if ($track !~ m/^[0-9]+$/) {
      print STDERR "add_track() -> given track isn't a number. You tried: \"$album\"\n";
      return;
   }

   #verify that this is a valid album
   whine("Album ID $album is not valid") if (! defined($album{$track}));
   whine("Track number $track is not valid") if (! defined(${$}));

   #add an album to the playlist, send the command
   $self->enqueue("ADD","ALBUM $album TRACK $track");
   $self->send_raw("ADD ALBUM $album TRACK $track");
}

##
# Error reporting goes here.
##
sub whine {
   print STDERR "*whine* " . $_ . "\n";
}


##
# Set a flag with the given data
#
##
sub setflag {
   my $self = shift;
   my ($flag,$data) = @_;

   $self->{"__$flag"} = $data;

   return;
}

##
# Grab a flag. Returns a flag's data
#
##
sub getflag {
   my $self = shift;
   my ($flag) = @_;

   return $self->{"__$flag"} if (defined($self->{"__$flag"}));
   return undef;
}

##
# Return the playlist
#
##
sub getplaylist {
   my $self = shift;

   return $self->{_playlist};
}

##
# Return an arrayref of the jukebox's albums
#
##
sub getalbums {
   my $self = shift;

   return $self->{_albums};
}

##
# Return an arrayref of the jukebox's tracks
#
##
sub gettracks {
   my $self = shift;

   return $self->{_tracks};
}

##
#
#
##
sub getstatus {
   my $self = shift;

   return $self->{_state};
}

"Jordan Sissel E<lt>psionic\@csh.rit.eduE<gt>"
