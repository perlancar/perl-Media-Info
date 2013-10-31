package Media::Info;

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       get_media_info
               );

# VERSION

our %SPEC;

$SPEC{get_media_info} = {
    v => 1.1,
    summary => 'Return information on media file/URL',
    args => {
        media => {
            summary => 'Media file/URL',
            schema  => 'str*',
            pos     => 0,
            req     => 1,
        },
    },
};
sub get_media_info {
    require Media::Info::Mplayer;

    Media::Info::Mplayer::get_media_info(@_);
}

1;
# ABSTRACT: Return information on media (music, video, etc) file/URL

=head1 SYNOPSIS

 use Media::Info qw(get_media_info);
 my $res = get_media_info(media => '/path/to/celine.mp4');

Sample result:

 [
   200,
   "OK",
   {
     audio_bitrate => 128000,
     audio_format  => 85,
     audio_rate    => 44100,
     duration      => 2081.25,
     num_channels  => 2,
     num_chapters  => 0,
   },
   {
     "func.raw_output" => "ID_AUDIO_ID=0\n...",
   },
 ]


=head1 DESCRIPTION

This module provides a common interface for Media::Info::* modules, which you
can use to get information about a media file (like video, music, etc) using
specific backends. Currently the only backend available is
L<Media::Info::Mplayer>, so this module uses that.


=head1 SEE ALSO

L<Video::Info> - This module is first written because I couldn't install
Video::Info. That module doesn't seem maintained (last release is in 2003 at the
time of this writing), plus I want a per-backend namespace organization instead
of per-format one, and a simple functional interface instead of OO interface.
