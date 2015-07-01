package App::Media::Info;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

our %SPEC;

$SPEC{media_info} = {
    v => 1.1,
    summary => 'Get information about media files/URLs',
    args => {
        media => {
            summary => 'Media files/URLs',
            schema => ['array*' => of => 'str*'],
            req => 1,
            pos => 0,
            greedy => 1,
            #'x.schema.entity' => 'filename_or_url',
            'x.schema.entity' => 'filename', # temp
        },
    },
};
sub media_info {
    require Media::Info;

    my %args = @_;

    my $media = $args{media};

    if (@$media == 1) {
        return Media::Info::get_media_info(media => $media->[0]);
    } else {
        my @res;
        for (@$media) {
            my $res = Media::Info::get_media_info(media => $_);
            unless ($res->[0] == 200) {
                warn "Can't get media info for '$_': $res->[1] ($res->[0])\n";
                next;
            }
            push @res, { media => $_, %{$res->[2]} };
        }
        [200, "OK", \@res];
    }
}

1;
# ABSTRACT:
