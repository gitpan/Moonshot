package Moonshot::Playlist;

#
# $Revision$
# $Author$
# $Date$
#

=head1 NAME

Moonshot::Playlist - A class to allow easy access to the playlist of the jukebox

=head1 SYNOPSIS

=head1 DESCRIPTION

This module handles playlist management and pruning

=over 4

=cut

#-------------------------------------------------------------------------------

=pod

=item Moonshot::Playlist-E<gt>new()

Create a new playlist object

=cut

sub new {
   my $proto = shift;

   my $self = {
		_list		=> []
	      };

   bless $self, $proto;
}

"Jordan Sissel E<lt>psionic\@csh.rit.eduE<gt>"
