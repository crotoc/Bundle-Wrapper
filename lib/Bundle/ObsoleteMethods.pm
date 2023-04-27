package Bundle::ObsoleteMethods;
use strict;
use warnings;
use parent qw(Bundle::Bio::Root::Root);
use String::Random;
use B qw( svref_2object );
use File::Path qw(make_path remove_tree);

=head1 NAME

:: - The great new ::!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use test;

    my $foo = test->new();
        ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut


sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    bless $self,$class;
    $self->setMethod("threads"=>5);
    $self->setMethod("chunk_size"=>1);
    return $self;
}



=head2 function2

=cut


sub redundant2eachrow
{
    my $class=shift;
    my $delim=$_[0];
    my $col=$_[1];
    my $fh=$_[2];
    
    while(my $line=<$fh>){
	chomp $line;
	my @line = split/\t/,$line;
	my @field = split/$delim/,$line[$col-1];
	foreach (@field)
	{
	    if($_){
		print "$line\t$_\n"
	    }
	}
    }
}

=item B<hash2str>;

=cut



    sub hash2str  ##hast2str by orderd keys and only values
{
    my $class=shift;
    my $hash=$_[0];
    my $key_order=$_[1];
    my $delimeter=$_[2];
    my $type=$_[3];
    my $str;
    my @str;
    
    
    $key_order=[keys %$hash],if (! $key_order);
    $delimeter = ",", if (! $delimeter);
    foreach (@$key_order){
	if(! exists $hash->{$_}){
	    $hash->{$_}='';
	}
	else{
	    if($type==2){
		push @str,"$_"."="."$hash->{$_}";
	    }
	    if($type==1){
		push @str,$hash->{$_};
	    }

	}
	
    }
    $str=join $delimeter,@str;
    return $str;
}


=item B<scale2array>

=cut 
sub scale2array
{
    my ($class,$str) = @_;
    my @array;
    my ($s,$e) = split/-/,$str;
	if($e){
	    @array=$s..$e;
	}
	else
	{
	    print STDERR "need max length";
	}
    
    return @array;
}



=item B<test_file_exist>;
test whether file exist
=cut

sub test_file_exist{
    my $self = shift;
    my @file = @_;
    my $flag;
    foreach (@file){
	if (-e $_){ print "TEST: $_ existed\n"; $flag=1;}
	else {print "TEST: $_ not existed\n";return 0;}
    }
    return $flag;
}



# sub function2 {
# }




=head1 AUTHOR

    Rui Chen, C<< <crotoc at gmail.com> >>

    =head1 BUGS

    Please report any bugs or feature requests to C<bug-test at rt.cpan.org>, or through
    the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=test>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc test


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

    L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=test>

    =item * CPAN Ratings

    L<https://cpanratings.perl.org/d/test>

    =item * Search CPAN

    L<https://metacpan.org/release/test>

    =back


    =head1 ACKNOWLEDGEMENTS


    =head1 LICENSE AND COPYRIGHT

    This software is Copyright (c) 2021 by Rui Chen.

    This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

    =cut

    1;



