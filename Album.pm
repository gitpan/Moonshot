package Moonshot::Album;

#
# $Revision: 1.5 $
# $Author: psionic $
# $Date: 2003/04/20 19:45:50 $
#

=head1 NAME

Moonshot::Album - An album (weee!) int the Moonshot jukebox

=head1 SYNOPSIS

=head1 DESCRIPTION

This is exactly what it looks like: An album object. It's an album entry in the Moonshot jukebox.

=over 4

=cut

#-------------------------------------------------------------------------------

#format:
# album_id "title" "artist" length tracks

sub new {
   my $proto = shift;
   my $self = {};

   my (%args) = @_;

   $self->{'Artist'} = (defined $args{'Artist'}) ? $args{'Artist'} : "unknown";
   $self->{'Title'} = (defined $args{'Title'}) ? $args{'Title'} : "unknown";
   $self->{'ID'} = (defined $args{'ID'}) ? $args{'ID'} : "unknown";
   $self->{'Length'} = (defined $args{'Length'}) ? $args{'Length'} : "unknown";
   $self->{'Tracks'} = (defined $args{'Tracks'}) ? $args{'Tracks'} : "unknown";

   bless $self, $proto;

   return $self;
}

sub artist {
   my $self = shift;
   return $self->{'Artist'};
}

sub title {
   my $self = shift;
   return $self->{'Title'};
}

sub length {
   my $self = shift;
   return $self->{'Length'};
}

sub id {
   my $self = shift;
   return $self->{'ID'};
}

sub tracks {
   my $self = shift;
   return $self->{'Tracks'};
}

"Jordan Sissel E<lt>psionic\@csh.rit.edu@<gt>"
