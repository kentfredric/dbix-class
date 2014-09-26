
use strict;
use warnings;

use Test::More;
use Test::Spelling;
use Path::Tiny qw(path);

# ABSTRACT: Pod Spelling Tests

set_spell_cmd('aspell list --lang en_GB');
add_stopwords( map { split /[ ]+/ } path('./xt/stopwords.txt')->lines_utf8 );
all_pod_files_spelling_ok('./lib');

done_testing;

