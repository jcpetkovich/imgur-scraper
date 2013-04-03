#!/usr/bin/perl -w
# imgur_scraper.pl --- Download files from imgur.
# Author: Jean-Christophe Petkovich <me@jcpetkovich.com>
# Created: 24 Apr 2012
# Version: 0.01

use v5.12;
use strict;
use warnings;
use URI;
use LWP::Simple;
use WWW::Mechanize;
use Getopt::Long qw( :config auto_help );
use HTML::TreeBuilder;
use File::Spec::Functions qw( canonpath catfile );
use Data::Dumper;

GetOptions();
my ( $imgur_album, $directory ) = @ARGV;

# shorthand
sub joinpath { canonpath( catfile(@_) ) }

# monkeypatch img_name
{

    package HTML::Element;

    sub img_name {
        ( URI->new( shift->attr("data-src") )->path_segments() )[-1];
    }
}

my $mech = WWW::Mechanize->new;
$mech->get($imgur_album);
my $content = $mech->content;
my $html    = HTML::TreeBuilder->new();
$html->parse($content);

my @images = $html->find_by_tag_name("img");

# print Dumper(\@images);

mkdir $directory unless -d $directory;

for my $image (@images) {

    my $class = $image->attr("class");

    # class attr of desired images seems to be "unloaded"
    if ( $class and $class =~ /^unloaded/ ) {

        # Get the imgur image id to use as a unique name
        my $image_name = $image->img_name();
        my ($image_id) = $image_name =~ /(.*)\..[^.]*$/;

        # Get the url of the image from the <img> tag
        my $image_url = $image->attr("data-src");
        $image_url =~ s/s\.jpg/.jpg/g;

        # Check the content type before downloading
        my ($content_type) = head $image_url;
        my ($path_extension) = $content_type =~ /image\/(.*)/;

        # Name the file based on the content type instead of trusting imgur
        my $path = joinpath( $directory, $image_id . '.' . $path_extension );

        say "Downloading: ", $image_url, " to: $path";

        getstore( $image_url, $path );
    }
}

__END__

=head1 NAME

imgur_scraper.pl - Simple imgur scraper.

=head1 SYNOPSIS

imgur_scraper.pl [options] url Directory

      -h --help      Print this help documentation

=head1 DESCRIPTION

Downloads imgur albums to a target directory.

=head1 AUTHOR

Jean-Christophe Petkovich, E<lt>me@jcpetkovich.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jean-Christophe Petkovich

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
