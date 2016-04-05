package Media::Info;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       get_media_info
               );

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
        backend => {
            summary => "Choose specific backend",
            schema  => ['str*', match => '\A\w+\z'],
        },
    },
};
sub get_media_info {
    no strict 'refs';

    my %args = @_;

    my @backends;
    if ($args{backend}) {
        @backends = ($args{backend});
    } else {
        @backends = qw(Ffmpeg Mplayer);
    }

    # try the first backend that succeeds
    for my $backend (@backends) {
        my $mod;
        my $mod_pm;
        if ($backend =~ /\A\w+\z/) {
            $mod    = "Media::Info::$backend";
            $mod_pm = "Media/Info/$backend.pm";
        } else {
            return [400, "Invalid backend '$backend'"];
        }
        next unless eval { require $mod_pm; 1 };
        my $func = \&{"$mod\::get_media_info"};
        my $res = $func->(media => $args{media});
        if ($res->[0] == 200) {
            $res->[3]{'func.backend'} = $backend;
        }
        return $res unless $res->[0] == 412;
    }

    if ($args{backend}) {
        return [412, "Backend '$args{backend}' not available, please install it first"];
    } else {
        return [412, "No Media::Info::* backends available, please install one"];
    }
}

1;
# ABSTRACT:

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
specific backends. Currently the available backends include
L<Media::Info::Mplayer> and L<Media::Info::Ffmpeg>.


=head1 SEE ALSO

L<Video::Info> - This module is first written because I couldn't install
Video::Info. That module doesn't seem maintained (last release is in 2003 at the
time of this writing), plus I want a per-backend namespace organization instead
of per-format one, and a simple functional interface instead of OO interface.
