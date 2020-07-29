package Media::Info;

# AUTHORITY
# DATE
# DIST
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

sub _type_from_name {
    require Filename::Audio;
    require Filename::Video;
    require Filename::Image;
    my $name = shift;

    Filename::Video::check_video_filename(filename => $name) ? "video" :
    Filename::Audio::check_audio_filename(filename => $name) ? "audio" :
    Filename::Image::check_image_filename(filename => $name) ? "image" : "unknown";
}

$SPEC{get_media_info} = {
    v => 1.1,
    summary => 'Return information on media file/URL',
    args => {
        media => {
            summary => 'Media file/URL',
            description => <<'_',

Note that not every backend can retrieve URL. At the time of this writing, only
the Mplayer backend can.

Many fields will depend on the backend used. Common fields returned include:

* `backend`: the `Media::Info::*` backend module used, e.g. `Ffmpeg`.
* `type_from_name`: either `image`, `audio`, `video`, or `unknown`. This
  is determined from filename (extension).


_
            schema  => 'str*',
            pos     => 0,
            req     => 1,
        },
        backend => {
            summary => "Choose specific backend",
            schema  => ['str*', match => '\A\w+\z'],
            completion => sub {
                require Complete::Module;

                my %args = @_;
                Complete::Module::complete_module(
                    word => $args{word},
                    ns_prefix => 'Media::Info',
                );
            },
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
        @backends = qw(Ffmpeg Mplayer Mediainfo);
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
            # add some common fields

            # backend
            $res->[3]{'func.backend'} = $backend;
            $res->[2]{backend} = $backend;
            $res->[2]{type_from_name} = _type_from_name($args{media});

            # mtime, ctime, filesize
            my @st = stat $args{media};
            $res->[2]{mtime} = $st[9];
            $res->[2]{ctime} = $st[10];
            $res->[2]{filesize} = $st[7];

            # video_longest_side, video_shortest_side, video_orientation (if not set by backend)
            if ($res->[2]{video_height} && $res->[2]{video_width}) {
                if ($res->[2]{video_height} > $res->[2]{video_width}) {
                    $res->[2]{video_longest_side}  = $res->[2]{video_height};
                    $res->[2]{video_shortest_side} = $res->[2]{video_width};
                    unless ($res->[2]{video_orientation}) {
                        my $rotate = $res->[2]{rotate} // '';
                        $res->[2]{video_orientation} = $rotate eq '90' || $rotate eq '270' ? 'landscape' : 'portrait';
                    }
                } else {
                    $res->[2]{video_longest_side}  = $res->[2]{video_width};
                    $res->[2]{video_shortest_side} = $res->[2]{video_height};
                    unless ($res->[2]{video_orientation}) {
                        my $rotate = $res->[2]{rotate} // '';
                        $res->[2]{video_orientation} = $rotate eq '90' || $rotate eq '270' ? 'portrait' : 'landscape';
                    }
                }
            }
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
L<Media::Info::Mplayer>, L<Media::Info::Ffmpeg>, L<Media::Info::Mediainfo>.


=head1 SEE ALSO

L<Video::Info> - C<Media::Info> is first written because I couldn't install
Video::Info. That module doesn't seem maintained (last release is in 2003 at the
time of this writing), plus I want a per-backend namespace organization instead
of per-format one, and a simple functional interface instead of OO interface.
