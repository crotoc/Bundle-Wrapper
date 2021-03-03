package Bundle::File;
use strict;
use warnings;
use parent qw(MyBase::Bio::Root::Root);
use Data::Dumper;
use parent qw(Bundle::Methods);
use parent qw(MyBase::Mysub);

sub new {
    my ($class,$file,$del) = @_;
    my $self = $class->SUPER::new();
    bless $self,$class;

    $self->setMethod("Prefix"=>$self->getPrefix($file,$del));
    $self->setMethod("Filename"=>$self->getFilename($file));
    $self->setMethod("Filedir"=>$self->getFiledir($file));
    return $self;
    
}

sub File {
    my ($self,$file,$del) = @_;

    $self->setMethod("Prefix"=>$self->getPrefix($file,$del));
    $self->setMethod("Filename"=>$self->getFilename($file));
    $self->setMethod("Filedir"=>$self->getFiledir($file));
    return $self;
    
}

1;
