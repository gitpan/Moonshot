package Moonshot::Track;

#
# $Revision: 1.4 $
# $Author: psionic $
# $Date: 2003/04/20 19:45:50 $
#

=head1 NAME

Moonshot::Track - A track entry in the Moonshot jukebox

=head1 SYNOPSIS

=head1 DESCRIPTION

A simple track entry.

=over 4

=cut

#-------------------------------------------------------------------------------

#format
# albumid track "album title" "title" "artist" length

sub new {
   my $proto = shift;
   my $self = {};

   my (%args) = @_;

   $self->{'AlbumID'} = (defined $args{'AlbumID'}) ? $args{'AlbumID'} : "unknown";
   $self->{'Track'} = (defined $args{'Track'}) ? $args{'Track'} : "unknown";
   $self->{'AlbumTitle'} = (defined $args{'AlbumTitle'}) ? $args{'AlbumTitle' }: "unknown";
   $self->{'TrackTitle'} = (defined $args{'TrackTitle'}) ? $args{'TrackTitle' }: "unknown";
   $self->{'Artist'} = (defined $args{'Artist'}) ? $args{'Artist'} : "unknown";
   $self->{'Length'} = (defined $args{'Length'}) ? $args{'Length'} : "unknown";

   bless $self, $proto;

   return $self;
}

sub as_string {
   my $self = shift;
   return "(" . $self->{'AlbumID'} . "/" . $self->{'Track'} . ") [" . $self->{'Artist'} . "] " . $self->{'Albumtitle'} . " - " . $self->{'TrackTitle'} . " :: " . $self->{'Length'} . " seconds";
}

sub title { my $self = shift; return $self->{'TrackTitle'}; }
sub album { my $self = shift; return $self->{'AlbumTitle'}; }
sub track { my $self = shift; return $self->{'Track'}; }
sub artist { my $self = shift; return $self->{'Artist'}; }
sub length { my $self = shift; return $self->{'Length'}; }
sub albumid { my $self = shift; return $self->{'AlbumID'}; }
"Jordan Sissel E<lt>psionic\@csh.rit.edu@<gt>"
