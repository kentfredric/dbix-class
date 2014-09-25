
use strict;
use warnings;

use Test::More;
use Test::Spelling;
use Comment::Spell;
use Path::Tiny qw(path);

# ABSTRACT: Comment Spelling Tests

set_spell_cmd('aspell list --lang en_GB');
add_stopwords( map { split /[ ]+/ } path('./xt/stopwords.txt')->lines_utf8 );

my %all_seen = ();

sub comment_file_spelling_ok {
    my $file = shift;
    my $name = shift || "Comment spelling for $file";
    if ( !-r $file ) {
        ok( 0, $name );
        diag("$file does not exist or is unreadable");
        return;
    }
    my $output;
    my $csp = Comment::Spell->new();
    $csp->set_output_string($output);
    $csp->parse_from_file($file);
    my @words = Test::Spelling::_get_spellcheck_results($output);
    chomp for @words;
    my $WL = \%Pod::Wordlist::Wordlist;
    @words = grep { !$WL->{$_} && !$WL->{ lc $_ } } @words;
    $all_seen{$_}++ for @words;
    my %seen;
    @seen{@words} = ();
    @words = sort keys %seen;

    # emit output
    my $ok = @words == 0;
    ok( $ok, "$name" );
    if ( !$ok ) {
        diag( "Errors:\n" . join '', map { "    $_\n" } @words );
    }
    return $ok;
}
my @files = all_pod_files('./lib');

unless (has_working_spellchecker) {
    exit plan skip_all => 'no working spell checker found';
}
plan tests => scalar @files;

for my $file (@files) {
    comment_file_spelling_ok($file);
}
use Text::Wrap;
if ( keys %all_seen ) {
    diag "\n";

    # Invert k => v to v => [ k ]
    my %values;
    push @{ $values{ $all_seen{$_} } }, $_ for keys %all_seen;

    my $labelformat = q[%6s: ];
    my $indent      = q[ ] x 10;

    diag qq[All incorrect words, by number of occurrences:\n] . join qq[\n], map {
        wrap( ( sprintf $labelformat, $_ ),
            $indent, join q[, ], sort @{ $values{$_} } )
      }
      sort { $a <=> $b } keys %values;
}
done_testing;

