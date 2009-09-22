package BuildStem;

use strict;
use warnings;

use Config;
use File::Basename;
use File::Spec;
use IO::File;

use Module::Build;

use vars qw(@ISA);
@ISA = qw(Module::Build);

sub ACTION_build {

    my ( $self ) = @_;

    if ( $self->config_data( 'build_demos' ) ) {
	$self->build_demo_scripts();
    }

    if ( $self->config_data( 'build_ssfe' ) ) {
	$self->build_ssfe();
    }

    $self->SUPER::ACTION_build();
}


# yes, hard coded, will fix some other time
sub build_ssfe {
    my ( $self ) = @_;
    print "Compiling ssfe\n";
    system( "cd extras; tar xzf sirc-2.211.tar.gz; cp sirc-2.211/ssfe.c ../demo" );
    system( "cc -o demo/ssfe demo/ssfe.c -ltermcap 2>/dev/null" );
    $self->add_to_cleanup(qw(demo/ssfe demo/ssfe.c ));
}



sub build_demo_scripts {
    my ( $self ) = @_;
    
    my $demo_dir = 'demo';

    my @files = <bin/demo/*>;

    for my $file (@files) {

	my $result = $self->copy_if_modified(
		    $file, $demo_dir, 'flatten');

	next unless $result ;
	
	$self->fix_shebang_line($result) if $self->is_unixish();
	$self->make_executable($result);
	$self->add_to_cleanup($result);
    }

}

###########################################################
# Find stem config files under the build dir and notify M::B about them.
sub process_conf_files {
	my ( $self ) = @_ ;
	my $files = $self->_find_file_by_type('stem','conf');
	return unless keys %$files;

	my $conf_dir = File::Spec->catdir($self->blib, 'conf');
	File::Path::mkpath( $conf_dir );

	foreach my $file (keys %$files) {
		my $result = $self->copy_if_modified(
		    $file, $conf_dir, 'flatten');
		next unless $result;
	}
	return 1;
}


###########################################################
# A horrible hack to attempt to find the location of a binary program...
# It would be nice if this functionality was already part of M::B
# or there was a CPAN module for it that didn't suck.
sub find_binary {
	my ( $self, $prog ) = @_ ;
	# make sure the command will succeed before extracting the path.
        if ( $self->do_system( "which $prog >/dev/null" ) ) {
		my $path = `which $prog` ;
                chomp $path;
                return $path;
	}
	return;
}



###########################################################
# Various convenience routines.
#
# To use ACTION_foo, call ./Build foo



# ACTION: grep through MANIFEST
# command line args:
#   files=<regex>
#
# do we need this action?
# 

sub ACTION_grep_manifest {

    my( $self ) = @_ ;

    my @manifest_sublist = $self->grep_manifest() ;

    print join( "\n", @manifest_sublist ), "\n" ;
    return;
}



# grep through all matched files
# command line args:
#   files=<regex> (default is all .pm files)
#   re=<regex>

sub ACTION_grep {

    my( $self ) = @_ ;

    my $args = $self->{'args'} ;

    my $file_regex = $args->{ files } || qr/\.pm$/ ;
    my $grep_regex = $args->{ re } or die "need grep regex" ;

    my @manifest_sublist = $self->grep_manifest( $file_regex ) ;

    local( @ARGV ) = @manifest_sublist ;

    while( <> ) {

        next unless /$grep_regex/ ;

        print "$ARGV:$. $_"
    }
    continue {

        close ARGV if eof ;
    }

    return;
}

my ( @manifest_lines ) ;

# MANIFEST helper subs

sub grep_manifest {

    my( $self, $file_regex ) = @_ ;

    $file_regex ||= $self->{ args }{ files } || qr/.*/ ;

    manifest_load() ;

    return grep( /$file_regex/, @manifest_lines ) ;
}

sub manifest_load {

    return if @manifest_lines ;

    @manifest_lines = grep ! /^\s*$|^\s*#/, read_file( 'MANIFEST' ) ;

    chomp @manifest_lines ;

    return ;
}

sub read_file {

    my ( $file_name ) = @_ ;

    local( *FH );

    open( FH, $file_name ) || die "Can't open $file_name $!";

    return <FH> if wantarray;

    read FH, my $buf, -s FH;
    return $buf;
}


1;
