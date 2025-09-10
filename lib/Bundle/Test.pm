package Bundle::Test;
use strict;
#use threads;
use warnings;
use base qw(Bundle::Bio::Root::Root);
use Data::Dumper;
use base qw(Bundle::Methods);
use IPC::Cmd qw/can_run/;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    bless $self,$class;
    return $self;
}

    
sub check{
    my $self = shift;
    my @file = @_;
    foreach (@file){
	if ($_){ print STDERR "TEST: check $_ ---> OK\n"; $self->{_check}->{$_}=1;}
	else {print STDERR "TEST: require $_ ---> NOT OK\n";$self->{_check}->{$_}=0;$self->throw("variable null\n")}
    }
}

sub checkBin{
    my ($self,@cmd)=@_;
    foreach (@cmd){
	if(! can_run($_)){
	    $self->throw("$_ does NOT exist in your PATH")
	}
    }
}


sub input{
    my $self = shift;
    my @file = @_;
    my $n;
    my $i;
    my @f;
    foreach my $file(@file){
	if(ref($file) eq 'ARRAY'){
	    push @f,@$file
	}else{
	    push @f,$file
	}
    }
    foreach my $file(@f){
	$i++;
	if (-e($file)){
	    if($i<=5)
	    {print STDERR "TEST: input OK ---> $file\n";}
	    $n++;
	    $self->{_input}->{$file}=1;
	}
	else {
	    if($i<=5){
		print STDERR "TEST: input NOT OK ---> $file\n";
	    }
	    $self->{_input}->{$file}=0;$self->throw("file $file absent\n")
	}
    }

    if(@f>5){
	print STDERR "TEST: input many! $n/".scalar(@f)." ---> OK\n";
    }

}

sub output{
    my $self = shift;
    my @file = @_;
    my $n=0;
    my $i;
    my @f;
    #print Dumper(@file);
    foreach my $file(@file){
	if(ref($file) eq 'ARRAY'){
	    push @f,@$file
	}else{
	    push @f,$file
	}
    }

    foreach (@f){
	$i++;
	if (-e $_){
	    if($i<=5)
	    {print STDERR "TEST: output OK ---> $_ \n";}
	    $n++;
	    $self->{_output}->{$_}=1;
	}
	else {
	    if($i<=5){
		print STDERR "TEST: output NOT OK --> $_ \n";
	    }
	    $self->{_output}->{$_}=0;}
    }
    #print Dumper $self->{_output};
    if(@f>5){
	print STDERR "TEST: output many! $n/".scalar(@f)." ---> OK\n";
    }
    
    my $flag=1;
    foreach(keys %{$self->{_output}}){
	#print Dumper $self->{_output}->{$_};
	$flag*=$self->{_output}->{$_};
    }
    if($flag){$self->{_isrun}=0;}else{$self->{_isrun}=1;}
}


1;
