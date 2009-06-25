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

	foreach my $file (keys %$files) {
		my $dest_dir = $file =~ /_demo$/ ? $demo_dir : $script_dir ;
		my $result = $self->copy_if_modified($file, $dest_dir, 'flatten') or next;
		$self->fix_shebang_line($result) if $self->is_unixish();
		$self->make_executable($result);
		if ( $result =~ /(?:run_stem$)|(?:_demo$)/ ) {
			my $result2 = $self->copy_if_modified($result, $self->base_dir(), 'flatten') or next;
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


1;
