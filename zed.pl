#!/usr/bin/perl

# Zed
#
# Contact: felipe at regex.pro.br
# Feedback and improvements are welcome.
#
#    Zed is a command line tool for editing text using Perl Regular Expressions.
#    Copyright (C) 2007  Felipe Nascimento Silva Pena
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use strict;
use warnings FATAL => 'all';

my $VERSION = '0.5-alpha';

do {
    print "zed version ", $VERSION, <<EOF;
    
    Copyright (C) 2007 Felipe Nascimento Silva Pena
    
    Usage: zed (file-with-regexps|regexps) (input-file|string)?
            
      file-with-regexps : File contains Perl regular expressions.
        Accepts: blank lines and comments (#).
        
    Examples:
      cat foo.txt | zed "s/foo/bar/g" > bar.txt
      zed "tr/a-c/d-f/" "abc"
      cat foo.txt | wc -l | zed "s/\\d+/Lines: \$&/"
      cat foo.txt | zed "1..3, d"
      
    More informations: http://zed.sf.net/
EOF
  exit;
} unless @ARGV;

$| = 1;

my @content = ();
my @regexps = ();

-e $ARGV[0] ? parse_re_file($ARGV[0]) : parse_re_arg($ARGV[0]);
read_file(defined $ARGV[1] ? $ARGV[1] : <STDIN>);
parse_file();

print @content;

sub read_file {
    if ($_[0] =~ /\n/ || !-e $_[0]) {
        @content = @_;
    } else {
        open(FILE, $_[0]) || die('Could not open file!');
        @content = <FILE>;
        close(FILE);
    }
}

sub parse_re_file {
    open(FILE, $_[0]) || die('Could not open file!');
    foreach (<FILE>) { chomp;
        unless (&parse_re) {
            print "Erro: Invalid expression! at line: ", $., "\n";
            close(FILE);
            exit 1;
        }
    }
    close(FILE);
}

sub parse_re_arg {
    $_ = shift;
    die "Erro: Invalid expression!\n" unless &parse_re;
}

sub parse_re {
    LOOP: {
        last LOOP if /\G\s*(?:#|\/\/).*/cg; 
        if (/\G\s*(-?\d+(?:\.\.\d*)?)\s*,\s*d\s*;?/cg) {
            push(@regexps, {'del' => defined $2 ? [1, $2, $1] : [0, $1]}); redo LOOP;
        }
        if (/\G\s*(?:(-?\d+(?:\.\.\d*)?)\s*,\s*)?(~?m?([^[:alnum:]])(?:(?!(?<!\\)\3).)+\3\s*[gimosx]*)\s*,\s*d\s*;?/cg) {
            push(@regexps, {'del' => defined $2 ? [1, $2, $1] : [0, $1]}); redo LOOP;
        }
        if (/\G\s*(?:(-?\d+(?:\.\.\d*)?)\s*,\s*)?(s([^[:alnum:]])(?:(?!(?<!\\)\3).)+\3(?:(?!(?<!\\)\3).)*\3[egimosx]*)\s*;?/cg) {
            push(@regexps, {defined $1 ? 'addr' : 'global' => [$1, $2]}); redo LOOP;
        }
        if (/\G\s*(?:(-?\d+(?:\.\.\d*)?)\s*,\s*)?((?:tr|y)([^[:alnum:]])(?:(?!(?<!\\)\3).)+\3(?:(?!(?<!\\)\3).)*\3[cds]*)\s*;?/cg) {
            push(@regexps, {defined $1 ? 'addr' : 'global' => [$1, $2]}); redo LOOP;
        }
    }
    return /\G\s*$/;
}

sub parse_file {
    for (@regexps) {
        if (defined $_->{'global'}) {
            re_global_apply($_->{'global'}[1]);
        } elsif (defined $_->{'addr'}) {
            re_addr_apply($_->{'addr'}[0], $_->{'addr'}[1]);
        } else {
            re_del_apply($_->{'del'}[0], $_->{'del'}[1], $_->{'del'}[2]);
        }
    }
}

sub re_global_apply {
    my $pattern = shift;
    my $text = join('', @content);
    eval qq(\$text =~ $pattern);
    @content = map { "$_\n" } split /\n|$/m, $text;
}

sub re_addr_apply {
    my ($addr, $pattern) = @_;
    $addr =~ /\.\./ ? rebuild_content($addr, $pattern) : eval qq(\$content[$addr] =~ $pattern);
}

sub re_del_apply {
    my ($match, $pattern, $interval) = @_;
    if ($match) {
        my (@new_cont, $line, $inverse);
        $inverse = 0;
        if (substr($pattern, 0, 1) eq '~') {
            $pattern = substr($pattern, 1, 1) eq 'm' ? substr($pattern, 2) : substr($pattern, 1);
            $inverse = 1;
        }
        $pattern = substr($pattern, 1, -1);
        eval qq(\$pattern = qr/$pattern/o);
        if (defined $interval) {
          if ($interval =~ /\.\./) {
              my (@lines, @slice);
              @slice    = split /\.\./, $interval;
              $slice[1] = $#content if !defined $slice[1] || $slice[1] > $#content;
              eval qq(push(\@new_cont, \@content[0..$slice[0]-1])) if $slice[0] > 0;
              eval qq(\@lines = \@content[$slice[0]..$slice[1]]);
              if ($inverse) {
                  for $line (@lines) { push(@new_cont, $line) if $line =~ /$pattern/; }
              } else {
                  for $line (@lines) { push(@new_cont, $line) unless $line =~ /$pattern/; }
              }
              eval qq(push(\@new_cont, \@content[$slice[1]..$#content])) if ++$slice[1] <= $#content;
          } else {
              eval qq(push(\@new_cont, \@content[0..$interval-1])) if $interval > 0;
              if ($inverse) {
                  push(@new_cont, $content[$interval]) if $content[$interval] =~ /$pattern/;
              } else {
                  push(@new_cont, $content[$interval]) unless $content[$interval] =~ /$pattern/;
              }
              eval qq(push(\@new_cont, \@content[$interval..$#content])) if ++$interval <= $#content;
          }
        } else {
            if ($inverse) {
                for $line (@content) { push(@new_cont, $line) if $line =~ /$pattern/; }
            } else {
                for $line (@content) { push(@new_cont, $line) unless $line =~ /$pattern/; }
            }
        }
        @content  = @new_cont;
        @new_cont = undef;
    } else {
        $pattern =~ /\.\./ ? rebuild_content($pattern, undef) : ($content[$pattern] = '');
    }
}

sub rebuild_content {
    my ($text, @new_cont, @slice, $pattern);
    @slice   = split /\.\./, shift;
    $pattern = shift;
    $slice[1] = $#content if !defined $slice[1] || $slice[1] > $#content;
    eval qq(push(\@new_cont, \@content[0..$slice[0]-1])) if $slice[0] > 0;
    if (defined $pattern) {
        eval qq(\$text = join('', \@content[$slice[0]..$slice[1]]));
        eval qq(\$text =~ $pattern);
        push(@new_cont, split /$/m, $text);
    }
    eval qq(push(\@new_cont, \@content[$slice[1]..$#content])) if ++$slice[1] <= $#content;
    @content  = @new_cont;
    @new_cont = undef;
}
