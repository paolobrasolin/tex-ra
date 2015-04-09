#!/usr/bin/perl

# Use best practices.
use strict;
use warnings;

# We need to fetch files from urls
use LWP::Simple;
# and correctly encode them
use Encode;
#use File::Slurp;

# ================================================================ PROCESS INDEX

# ------------------------------------------------------------------- FETCH HTML

print "Fetching index... ";
#my $i = read_file( '_internet/ra' ) ;
my $i = get "http://qntm.org/ra";
die "Error!\n" unless defined $i;
$i = encode('utf-8', $i);

# -------------------------------------------------------------- EXTRACT CONTENT

# Extract the id (i.e. url) and the title of each chapter.
my @ids = ( $i =~ /^\s+href='\/(.*)'$/gm );
my @titles = ( $i =~ /^\s+>(.*)<\/a>$/gm );

# Chapter "aum" needs its title manually fixed to render devanagari
$titles[15] = '{\dn:}';

# Now we isolate the introduction.
# Remove vertical whitespace for easier handling.
$i =~ s/\v+//g;
# Extract the introduction
$i =~ s/.*(?:id="content">)(.*?)(?:<p><small>).*/$1/;
# Do a basic formatting
$i =~ s/<i>(bona fide)<\/i>/\\emph{$1}/g;
$i =~ s/<.><.>//g;
$i =~ s/<..><..>/\\\\~\\\\\n/g;

# ----------------------------------------------------------------------- OUTPUT

# Write the latex chapter list.
die "Error!\n" unless open(my $f, '>', 'chapters.tex');
for my $i (0 .. $#ids) {
  print $f '\chapter{'."$titles[$i]}\n";
  print $f '\input{chapters/'."$ids[$i]}\n";
}
close $f;

# Write the latex teaser.
die "Error!\n" unless open(my $g, '>', 'teaser.tex');
print $g $i;
close $g;

print "Done!\n";

# ============================================================= PROCESS CHAPTERS

# Hash of code needing special care (HTML => LATEX).
my %specials = (
  # using unicode and xetex spares these: áãéíóöāćčīÞ
  'א**' => '$\aleph^{**}$',
  '√3' => '$\sqrt{3}$',
  'L<sup>A</sup>T<sub>E</sub>X' => '\LaTeX',
  '+ <var>S</var><sub><var>t</var>;<var>&tau;</var></sub>' => '$+S_{t;\tau;}$',
  '10<sup>18</sup>' => '$10^{18}$',
  'XE<sub>171</sub>' => '$\mathrm{XE}_{171}$',
  'SO<sub>2</sub>' => '\ce{SO}',
  'O<sub>2</sub>' => '\ce{O2}',
  'ζ' => '$\zeta$',
  'ι' => '$\iota$',
  'χ' => '$\chi$',
  'EMμ' => '$\mathrm{EM}\mu$',
  '&amp;' => '\&',
);

# Hash of typos I found (ERROR => FIX).
my %typos = (
  # sufficiently
  '<tt></tt>zui ixuv ixuv' => '<tt>zui ixuv ixuv</tt>',
  '<tt></tt>dulaku' => '<tt>dulaku</tt>',
  # know
  '<tt></tt>uum' => '<tt>uum</tt>',
  # protagonism
  '<P>' => '<p>'
);

# Now we process each chapter.
foreach (@ids) {

  # ----------------------------------------------------------------- FETCH HTML

  print "Fetching chapter $_... ";
  #my $t = read_file( '_internet/'.$_ );
  my $t = get "http://qntm.org/".$_;
  die "Error!\n" unless defined $t;
  $t = encode('utf-8', $t);

  # Remove vertical whitespace for easier handling.
  $t =~ s/\v+/ /g;
  
  # ------------------------------------------------------------ EXTRACT CONTENT

  # Set starting marker.
  # First chapter has no "Previously" link and is handled by second option:
  my $bef = 'Previously<\/a><\/h4>|id="content">';
  # Set ending marker.
  # Every chapter ends with '<p>&nbsp', some with styling:
  my $aft = '<p[^>]*>\&nbsp;';
  # Extract everything between markers.
  # Note central group must be lazy: (e.g. see chapter "just")
  $t =~ s/.*(?:$bef)(.*?)(?:$aft).*/$1/;

  # ------------------------------------------------------------------ TIDY HTML

  # Strip all comments.
  $t =~ s/<!--.*?-->//g;

  # Remove excess horizontal whitespace.
  $t =~ s/(^|>)\s+(<|$)/$1$2/g;

  # Chapter "work" has a <div> used for alignment.
  if ($_ eq 'work') {
    my $patch = '';
    # Catch <div>s content.
    $patch = $1 if $t =~ /<div[^>]*>(.*)<\/div>/;
    # Make children inherit alignment.
    $patch =~ s/<(p|h4)>/<$1 style="text-align: right;">/g;
    # Replace the <div> with formatted <p>s.
    $t =~ s/<div.*div>/$patch/;
  }

  # Fix typos.
  while (my ($typo, $fix) = each %typos) {
    $t =~ s/\Q$typo/$fix/g;
  }

  # ----------------------------------------------------------------- CHECKPOINT

  # We now have minimized and clean html. It would be really easy to produce
  # a cleaner html version of the documents now, e.g. grouping <p>s into <div>s
  # for aligment purposes, styling them with classes, etc.
  # But that's not what we want.

  # I'll just leave this here for sanity checks:
  #$t =~ s/(<\/(?:p|h4)>)/$1\n\n/g;

  # Note: css styling is not really uniform since some semicolons are missing.

  # ----------------------------------------------------------- CONVERT TO LATEX

  # Format emphasis.
  $t =~ s/<(i|em)>(.*?)<\/\1>/\\emph{$2}/g;
  # Need a second pass to handle nesting!
  $t =~ s/<(i|em)>(.*?)<\/\1>/\\emph{$2}/g;

  # Format magic.
  $t =~ s/<(tt|code)>(.*?)<\/\1>/\\magic{$2}/g;

  # Format the stars.
  $t =~ s/>\*</>\\gostar</g;

  # Format words and letters needing special care.
  while (my ($html, $latex) = each %specials) {
    $t =~ s/\Q$html/$latex/g;
  }

  # Format math.
  $t =~ s/<var>(.*?)<\/var>/\$$1\$/g;

  # Aligning every paragraph would not be smart. Changing alignment at
  # transitions between worlds is, so we need to detect them.
  # Doing this with ease using just regex would need alignment data to be
  # both at the opening and at the closing html tags. That's easily done:
  $t =~ s/<(p|h4)[^>]*right[^>]*>(.*?)<\/\1>/r-{$2}-r/g;
  $t =~ s/<(p|h4)[^>]*center[^>]*>(.*?)<\/\1>/c-{$2}-c/g;
  $t =~ s/<(p|h4)>(.*?)<\/\1>/l-{$2}-l/g;
  # Now we set the initial world
  $t =~ s/^l-{/\\goreal\n\n/;
  $t =~ s/^c-{/\\gobetween\n\n/;
  $t =~ s/^r-{/\\gotannaka\n\n/;
  # and format transitions with user defined commands
  $t =~ s/}-[^l]l-{/\n\n\\goreal\n\n/g;
  $t =~ s/}-[^c]c-{/\n\n\\gobetween\n\n/g;
  $t =~ s/}-[^r]r-{/\n\n\\gotannaka\n\n/g;
  # while ignoring redundant information
  $t =~ s/}-(l|c|r)\1-{/\n\n/g;
  $t =~ s/}-(l|c|r)$/\n/;
  # Done!

  # Format single quotes discerning apostrophes.
  $t =~ s/\B'(.*?)'\B/`$1'/gm;
  # Format closed double quotes.
  $t =~ s/"(.*?)"/``$1''/gm;
  # Close and format unclosed double quotes.
  $t =~ s/"(.*)$/``$1''/gm;

  #$t =~ s/[[:ascii:]]//g;
  #print $t;
  
  # --------------------------------------------------------------------- OUTPUT
  die "Error!\n" unless open(my $f, '>', 'chapters/'.$_.'.tex');
  print $f $t;
  close $f;

  print "Done!\n";

}

# ========================================================================== EOF