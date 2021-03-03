package Bundle::Wrapper;
use strict;
use warnings;
use parent qw(MyBase::Bio::Root::Root);
use Data::Dumper;
use parent qw(Bundle::Test);
use parent qw(Bundle::Multifork);
use parent qw(Bundle::MCEMap);
use parent qw(Bundle::File);

=head1 NAME

Bundle::Wrapper - The great new Bundle::Wrapper!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Bundle::Wrapper;

    my $foo = Bundle::Wrapper->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub new {
    my ($class,$opt) = @_;
    my $self = $class->SUPER::new();

    bless $self,$class;
    $self->setMethod("opt"=>$opt);
    $self->setMethod("isrun"=>1);
    $self->setMethod("threads"=>$opt->{threads});
    $self->setMethod("chunk_size"=>1);
    return $self;
}

=head1 AUTHOR

Rui Chen, C<< <crotoc at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bundle-wrapper at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bundle-Wrapper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bundle::Wrapper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Bundle-Wrapper>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Bundle-Wrapper>

=item * Search CPAN

L<https://metacpan.org/release/Bundle-Wrapper>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Rui Chen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut


1;
