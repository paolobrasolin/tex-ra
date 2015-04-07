#!/usr/bin/perl

# best practices
use strict;
use warnings;

# turn on autoflush
$|++;

#use File::Slurp;
use LWP::Simple;
use Encode;

print "Fetching index... ";
my $index = get "http://qntm.org/ra";
#my $ra = read_file( 'ra' ) ;
die "Error!\n" unless defined $index;
$index = encode('utf-8', $index);

my @ids = ( $index =~ /^\s+href='\/(.*)'$/gm );
my @titles = ( $index =~ /^\s+>(.*)<\/a>$/gm );

# ugly fix for chapter "aum"
#@titles[15] = 'AUM'; # TO BE FIXED

open(my $f, '>', 'chapters.tex') or die;
for my $i (0 .. $#ids) {
  print $f '\chapter{'."$titles[$i]}\n";
  print $f '\input{chapters/'."$ids[$i]}\n";
}
close $f;

print "Done!\n";

#my @ids = ('city','sufficiently','ignorance','isnt','know','ragdoll','broken','thaumonuclear','jesus','space','yantra','daemons','abstract','death','zero','aum','bare','people','deeper','cabal','protagonism','scrap','inferno','darkness','direct','war','real','hate','thursdayism','akheron','all','rajesh','machine','work','just','destructor');

my %words = (
  'א**' => '$\aleph^{**}$',
  '√3' => '$\sqrt{3}$',
  'L<sup>A</sup>T<sub>E</sub>X' => '\LaTeX',
  '+ <var>S</var><sub><var>t</var>;<var>&tau;</var></sub>' => '$+S_{t;\tau;}$',
  '10<sup>18</sup>' => '$10^{18}$',
  'XE<sub>171</sub>' => '$\mathrm{XE}_{171}$',
  'SO<sub>2</sub>' => '$\mathrm{SO}_2$',
  'O<sub>2</sub>' => '$\mathrm{O}_2$'
);

my %characters = (
  # using xetex spares these: áãéíóöāćčīÞ
  'ζ' => '$\zeta$',
  'ι' => '$\iota$',
  'EMμ' => '$\mathrm{EM}\mu$',
  'χ' => '$\chi$',
  '<var>c</var>' => '$c$',
  '<var>N</var>' => '$N$',
  '<var>X</var>' => '$X$',
  '<var>Y</var>' => '$Y$',
  '<var>Z</var>' => '$Z$',
  '<var>S</var>' => '$S$',
  '&amp;' => '\&',
);

foreach (@ids) {
  print "Fetching chapter $_... ";
  #my $t = read_file( '_internet/'.$_ ) ;
  my $t = get "http://qntm.org/".$_;
  die "Error!\n" unless defined $t;
  $t = encode('utf-8', $t);
  
  # remove all vertical whitespace
  $t =~ s/\v+/ /g;
  # extract content between markers
  my $bef = 'Previously<\/a><\/h4>|id="content">';
  my $aft = '<p[^>]*>\&nbsp;';
  # lazyness of central group is needed by chapter just
  $t =~ s/.*(?:$bef)(.*?)(?:$aft).*/$1/;
  # strip all comments
  $t =~ s/<!--.*?-->//g;
  
  # ugly fix needed by the chapter "work"
  my $patch = '';
  $patch = $1 if $t =~ /<div[^>]*>(.*)<\/div>/;
  $patch =~ s/<p>/<p style="text-align: right;">/g;
  $t =~ s/<div.*div>/$patch/;
  # ugly fix needed by the chapter "protagonism"
  $t =~ s/<P>/<p>/;
  # fix typo in chapter "know"
  $t =~ s/\\magic{}uum/\\magic{uum}/;
  
  # handle special words
  while (my ($html, $latex) = each %words) {
    $t =~ s/\Q$html/$latex/g;
  }
  while (my ($html, $latex) = each %characters) {
    $t =~ s/\Q$html/$latex/g;
  }

  # format emphasis
  $t =~ s/<(i|em)>(.*?)<\/\1>/\\emph{$2}/g;
  # need a second pass to handle nesting
  $t =~ s/<(i|em)>(.*?)<\/\1>/\\emph{$2}/g;
  # format magic
  $t =~ s/<(tt|code)>(.*?)<\/\1>/\\magic{$2}/g;

  # at this point only paragraphs and transitions are left

  # remove whitespace between tags
  $t =~ s/(^|>)\s+(<|$)/$1$2/g;

  # preformat paragraphs and transitions
  $t =~ s/<(p|h4)[^>]*right[^>]*>(.*?)<\/\1>/r-{$2}-r/g;
  $t =~ s/<(p|h4)[^>]*center[^>]*>(.*?)<\/\1>/c-{$2}-c/g;
  $t =~ s/<(p|h4)[^>]*>(.*?)<\/\1>/l-{$2}-l/g;
  # format transition symbols
  $t =~ s/{\*}/{\\switchsymbol}/g;
  # format transitions
  $t =~ s/(^|}-[^l])l-{/\n\n\\goreal\n\n/g;
  $t =~ s/(^|}-[^c])c-{/\n\n\\gobetween\n\n/g;
  $t =~ s/(^|}-[^r])r-{/\n\n\\gotannaka\n\n/g;
  $t =~ s/}-([lcr])(\1-{|$)/\n\n/g;

  # format quotation marks
  $t =~ s/"(.*?)"/``$1''/g;
  # correct unclosed ones
  $t =~ s/"(.*?$)/``$1''/g;

  #$t =~ s/[[:ascii:]]//g;
  #print $t;
  
  open(my $f, '>', 'chapters/'.$_.'.tex') or die;
  print $f $t;
  close $f;

  print "Done!\n";
}
