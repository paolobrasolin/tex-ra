#!/usr/bin/perl
# ################################################################ LET'S DANCE #

# Use best practices.
use strict;
use warnings;

# Enable autoflush.
$|++;

# ============================================================== FILE FETCHING =

# Use needed modules.
use File::Slurp;
use LWP::Simple;
use Encode;

# Set up local and remote location of files.
my $dir_root = 'html/';
my $url_root = 'http://qntm.org/';

# Create local storage directory.
mkdir $dir_root;

# Define file fetching subroutine.
sub Fetch {
  my $filename = $_[0];
  print "\nFilename: ".$filename."\n";
  my $local_filename = $dir_root.$filename;
  my $remote_filename = $url_root.$filename;
  my $in_file;
  if (!-f $local_filename) {
    print "  Fetching remote file...";
    $in_file = get $remote_filename;
    die " Download error!\n" unless defined $in_file;
    $in_file = encode('utf-8', $in_file);
    my $out_file;
    die " Writing error!\n" unless open($out_file, '>', $local_filename);
    print $out_file $in_file;
    close $out_file;
  } else {
    print "  Fetching local copy...";
  }
  $in_file = read_file $local_filename;
  print " Done!\n";
  return $in_file;
}

# ====================================================== CHAPTERS EDITS HASHES =

my %edits = (
  "city"          => { "'Scuse" => "’Scuse" },
  "sufficiently"  => { '<tt></tt>zui ixuv ixuv' => '<tt>zui ixuv ixuv</tt>',
                       '<tt></tt>dulaku' => '<tt>dulaku</tt>',
                       "my tutors' knowledge" => "my tutors’ knowledge",
                       "two weeks' preparation" => "two weeks’ preparation" },
  "ignorance"     => { "- crucially -" => "-- crucially --",
                       '<tt></tt>uum' => '<tt>uum</tt>',
                       '<tt></tt>eset' => '<tt>eset</tt>',
                       '<tt></tt>kafanu' => '<tt>kafanu</tt>' },
  "isnt"          => { "Atlantis' fuel system" => "Atlantis’ fuel system",
                       "Atlantis' last engine" => "Atlantis’ last engine",
                       "40 miles' range" => "40 miles’ range",
                       "the Fernos' spot" => "the Fernos’ spot",
                       'O<sub>2</sub>' => 'O₂' },
  "know"          => { '<tt>ltf15</tt>' => '{\Terminal ltf15}',
                       '<tt></tt>uum' => '<tt>uum</tt>',
                       "four weeks' rent" => "four weeks’ rent",
                       '+ <var>S</var><sub><var>t</var>;<var>&tau;</var></sub>'
                         => '{\STensor}' },
  "ragdoll"       => { "Tómas' response" => "Tómas’ response" },
  "broken"        => { "Atlantis' nose cone" => "Atlantis’ nose cone", 
                       '√3' => '{\SqrtThree}'  },
  "thaumonuclear" => { 'SO<sub>2</sub>' => 'SO₂' },
  "jesus"         => {},
  "space"         => { "five years' time" => "five years’ time",
                       'O<sub>2</sub>' => 'O₂' },
  "yantra"        => {},
  "daemons"       => { "St. Nicholas' Hill" => "St.~Nicholas’ Hill",
                       'L<sup>A</sup>T<sub>E</sub>X' => '\LaTeX' },
  "abstract"      => { 'א**' => '\AlephStars' },
  "death"         => {},
  "zero"          => {},
  "aum"           => {},
  "bare"          => { "yards' difference" => "yards’ difference" },
  "people"        => {},
  "deeper"        => { "mages' toolboxes" => "mages’ toolboxes",
                       "'88" => "’88",
                       "'89" => "’89"
#                       'ζ' => '$\zeta\kern-1.23999pt$', # among italic, unkern
#                       'ι' => '$\iota$', # has no kerning
#                       'EMμ' => '\textit{EM$\mu$}',
#                       'χ' => '$\chi$' }, # loner among roman, don't unkern
},
  "cabal"         => { "'72" => "’72" },
  "protagonism"   => { '..........' => '\LongEllipsis' },
  "scrap"         => { '10<sup>18</sup>' => '10¹⁸' },
  "inferno"       => {},
  "darkness"      => {},
  "direct"        => { "Henders' simple answer" => "Henders’ simple answer",
                       '10<sup>18</sup>' => '10¹⁸' },
  "war"           => {},
  "real"          => { "full Moons' worth" => "full Moons’ worth",
                       'XE<sub>171</sub>' => 'XE₁₇₁' },
  "hate"          => { "Actuals' next step" => "Actuals’ next step" },
  "thursdayism"   => {},
  "akheron"       => {},
  "all"           => { "the screens' content" => "the screens’ content" },
  "rajesh"        => { "read others' papers" => "read others’ papers",
                       "'72" => "’72",
                       "'73" => "’73" },
  "machine"       => { "astronauts' lives" => "astronauts’ lives",
                       'א**' => '\AlephStars' },
  "work"          => {},
  "just"          => { "'ports" => "’ports",
                       "the blinds' edges" => "the blinds’ edges" },
  "destructor"    => {}
);

# ======================================================== CHAPTERS PROCESSING =

while (my ($id, $edit) = each %edits) {

  # ------------------------------------------------------------ PRELIMINARIES -

  my $t = Fetch $id;
  printf "  Processing...";

  # Remove vertical whitespace for easier handling.
  $t =~ s/\v+/ /g;
  
  # ---------------------------------------------------------- EXTRACT CONTENT -

  # Starting marker. 1st chapter has no "Prev." It's handled by the 2nd option:
  my $bef = 'Previously<\/a><\/h4>|id="content">';
  # Ending marker. Every chapter ends with '<p>&nbsp', some with styling:
  my $aft = '<p[^>]*>\&nbsp;';
  # Note central group must be lazy: (e.g. see chapter "just")
  $t =~ s/.*(?:$bef)(.*?)(?:$aft).*/$1/;

  # ---------------------------------------------------------------- TIDY HTML -

  # Strip comments.
  $t =~ s/<!--.*?-->//g;

  # Strip excess horizontal whitespace (leading, inter-tags, trailing).
  $t =~ s/(^|>)\s+(<|$)/$1$2/g;

  # Chapter "work" has a <div> used for alignment.
  if ($id eq 'work') {
    my $patch = '';
    # Catch <div>s content.
    $patch = $1 if $t =~ /<div[^>]*>(.*)<\/div>/;
    # Make children inherit alignment.
    $patch =~ s/<(p|h4)>/<$1 style="text-align: right;">/g;
    # Replace the <div> with formatted <p>s.
    $t =~ s/<div.*div>/$patch/;
  }

  # Chapter "protagonism" has uppercase paragraph tags.
  if ($id eq 'protagonism') {
    $t =~ s/<P>/<p>/g;
  }

  # ------------------------------------------------------------------ EDITING -

  # Apply edits.
  while (my ($original, $fixed) = each $edit) {
    $t =~ s/\Q$original/{\\red $fixed}/g;
  }

  # I'll just leave this here for sanity checks:
#  $t =~ s/(<\/(?:p|h4)>)/$1\n\n/g;

  # --------------------------------------------------------- CONVERT TO LATEX -

  # Format emphasis. Two passes to handle nesting.
  $t =~ s/<(i|em)>(.*?)<\/\1>/{\\em $2}/g;
  $t =~ s/<(i|em)>(.*?)<\/\1>/{\\em $2}/g;

  # Format magic.
  $t =~ s/<(tt|code)>(.*?)<\/\1>/{\\Magic $2}/g;

  # Format the stars.
#  $t =~ s/>\*</>\\gostar</g;
  # Actually, don't. I am just going to suppress them anyways.

  # Format math.
  $t =~ s/<var>(.*?)<\/var>/{\\em $1}/g;

  # Aligning every paragraph would not be smart. Changing alignment at
  # transitions between worlds is, so we need to detect them.
  # Doing this with ease using just regex would need alignment data to be
  # both at the opening and at the closing html tags. That's easily done:
  $t =~ s/<(p|h4)[^>]*right[^>]*>(.*?)<\/\1>/r-<$2>-r/g;
  $t =~ s/<(p|h4)[^>]*center[^>]*>(.*?)<\/\1>/c-<$2>-c/g;
  $t =~ s/<(p|h4)>(.*?)<\/\1>/l-<$2>-l/g;
  # We use angle brackets since no other html tags are left.

  # Suppress the stars.
  $t =~ s/.-<\*>-.//g;

  # Ok, nice. Now we have a single line nicely formatted as
  #   a-<...>-ab-<...>-bc-<...  ...  ...>-yz-<...>-z
  # where letters denote alignment data.

  # Now we set the initial world
  $t =~ s/^l-</\\SetWorld{reality}\n\n/;
  $t =~ s/^c-</\\SetWorld{between}\n\n/;
  $t =~ s/^r-</\\SetWorld{tannaka}\n\n/;
  # and format transitions with user defined commands
  $t =~ s/>-[^l]l-</\n\n\\SwitchWorld{reality}\n\n/g;
  $t =~ s/>-[^c]c-</\n\n\\SwitchWorld{between}\n\n/g;
  $t =~ s/>-[^r]r-</\n\n\\SwitchWorld{tannaka}\n\n/g;
  # while ignoring redundant
  $t =~ s/>-(l|c|r)\1-</\n\n/g;
  # and trailing information
  $t =~ s/>-(l|c|r)$/\n/;

  # Format ellipsis.
  $t =~ s/\.\.\./…/g;

  # A pinch of dashes.
  $t =~ s/\s?--\s?/ — /g;
  # Ampersands.
  $t =~ s/&amp;/\\&/g;
  # Slashes. To allow breaks.
#  $t =~ s/\//\\raSlash /g;

  # Format apostrophes. (Handles emphasis on the left.)
  $t =~ s/\b(?<=})?'\b/’/g;

  # Catch closed single quotes.
  $t =~ s/'(.*?)'/<$1>/gm;
  # Catch closed double quotes.
  $t =~ s/"(.*?)"/<$1>/gm;
  # Catch unclosed double quotes.
  $t =~ s/"(.*)$/<$1>/gm;
  # We use angle brackets since no other html tags are left.
  # Format first and second level quotes, british style.
  $t =~ s/<([^<>]*)>/‘$1’/g;
  $t =~ s/<([^<>]*)>/“$1”/g;

  # --------------------------------------------------------------------- OUTPUT

  my $f;

  die "Error!\n" unless open($f, '>', 'chapters/'.$id.'.tex');
  print $f $t;
  close $f;

  print " Done!\n";

}

print "\nComplete success!\n\n";

# ######################################################################## EOF #
