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


sub process_script_files {
	my ( $self ) = @_ ;
	my $files = $self->find_script_files();
	return unless keys %$files;

	my $script_dir = File::Spec->catdir($self->blib, 'script');
	my $demo_dir   = File::Spec->catdir($self->blib, 'demo');
	File::Path::mkpath( $script_dir );
	File::Path::mkpath( $demo_dir );
    $self->add_to_cleanup($demo_dir);

	foreach my $file (keys %$files) {
		my $dest_dir = $file =~ /_demo$/ ? $demo_dir : $script_dir ;
		my $result = $self->copy_if_modified($file, $dest_dir, 'flatten') or next;
		$self->fix_shebang_line($result) if $self->is_unixish();
		$self->make_executable($result);
        my $demo_run_dir = File::Spec->catdir($self->base_dir(), 'demo');
		if ( $result =~ /(?:run_stem$)|(?:_demo$)/ ) {
			my $result2 = $self->copy_if_modified($result, $demo_run_dir, 'flatten') or next;
			$self->add_to_cleanup($result2);
		}
	}
	return 1;
}

sub process_conf_files {
	my ( $self ) = @_ ;
	my $files = $self->_find_file_by_type('stem','conf');
	return unless keys %$files;

	my $conf_dir = File::Spec->catdir($self->blib, 'conf');
	File::Path::mkpath( $conf_dir );

	foreach my $file (keys %$files) {
		my $result = $self->copy_if_modified($file, $conf_dir, 'flatten') or next;
		$self->fix_shebang_line($result) if $self->is_unixish();
	}
	return 1;
}

sub find_binary {
	my ( $self, $prog ) = @_ ;
	if ( $self->do_system( "which $prog >/dev/null" ) ) {
		return `which $prog` ;
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
