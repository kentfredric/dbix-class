use strict;
use warnings;

use Test::More;

# ABSTRACT: Execute PerlCritic on everything

use Test::Perl::Critic -profile => './perlcritic.rc';
use Perl::Critic::Utils;

## HACK: Convince Perl::Critic that pod files are perl files
{
    use Perl::Critic::Exception::Fatal::Generic qw{ throw_generic };
    sub _is_perl {
        my ($file) = @_;

        #Check filename extensions
        return 1 if $file =~ m{ [.] PL    \z}xms;
        return 1 if $file =~ m{ [.] p[lm] \z}xms;
        return 1 if $file =~ m{ [.] t     \z}xms;
        return 1
          if $file =~ m{ [.] pod   \z}xms
          ;    # This is the only difference from Perl::Critic::Utils

        #Check for shebang
        open my $fh, '<', $file or return;
        my $first = <$fh>;
        close $fh or throw_generic "unable to close $file: $!";

        return 1 if defined $first && ( $first =~ m{ \A [#]!.*perl }xms );
        return;
    }

    no warnings 'redefine';
    my %SKIP_DIR => map { $_ => 1 } qw( CVS RCS .svn _darcs {arch} .bzr .cdv .git .hg .pc _build blib );

    *Perl::Critic::Utils::all_perl_files = sub {

        # Recursively searches a list of directories and returns the paths
        # to files that seem to be Perl source code.  This subroutine was
        # poached from Test::Perl::Critic.

        my @queue      = @_;
        my @code_files = ();

        while (@queue) {
            my $file = shift @queue;
            if ( -d $file ) {
                opendir my ($dh), $file or next;
                my @newfiles = sort readdir $dh;
                closedir $dh;

                @newfiles = File::Spec->no_upwards(@newfiles);
                @newfiles = grep { not $SKIP_DIR{$_} } @newfiles;
                push @queue, map { File::Spec->catfile( $file, $_ ) } @newfiles;
            }

            if ( ( -f $file ) && !Perl::Critic::Utils::_is_backup($file) && _is_perl($file) ) {
                push @code_files, $file;
            }
        }
        return @code_files;
    };
}
all_critic_ok();
