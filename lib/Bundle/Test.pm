package Bundle::Test;
use strict;
#use threads;
use warnings;
use base qw(MyBase::Bio::Root::Root);
use Data::Dumper;
use base qw(Bundle::Methods);
use base qw(MyBase::Mysub);
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
	if ($_){ print "TEST: check $_ ok\n"; $self->{_check}->{$_}=1;}
	else {print "TEST: require $_ not ok\n";$self->{_check}->{$_}=0;$self->throw("variable null\n")}
    }
}

sub checkBin{
    my ($self,@cmd)=@_;
    foreach (@cmd){
	if(! can_run($_)){
	    $self->throw("$_ does not exist in your PATH")
	}
    }
}


sub input{
    my $self = shift;
    my @file = @_;
    my $n;
    my $i;
    foreach my $file(@file){
	$i++;
	if (-e($file)){
	    if($i<=5)
	    {print "TEST: input $file ok\n";}
	    $n++;
	    $self->{_input}->{$file}=1;
	}
	else {
	    if($i<=5){
		print "TEST: input $file not ok\n";
	    }
	    $self->{_input}->{$file}=0;$self->throw("file $file absent\n")
	}
    }

    if(@file>5){
	print "TEST: input many! $n/".scalar(@file)." are ok\n";
    }

}

sub output{
    my $self = shift;
    my @file = @_;
    my $n=0;
    my $i;
    #print Dumper(@file);
    foreach (@file){
	$i++;
	if (-e $_){
	    if($i<=5)
	    {print "TEST: output $_ ok\n";}
	    $n++;
	    $self->{_output}->{$_}=1;
	}
	else {
	    if($i<=5){
		print "TEST: output $_ not ok\n";
	    }
	    $self->{_output}->{$_}=0;}
    }
    #print Dumper $self->{_output};
    if(@file>5){
	print "TEST: output many! $n/".scalar(@file)." are ok\n";
    }
    
    my $flag=1;
    foreach(keys %{$self->{_output}}){
	#print Dumper $self->{_output}->{$_};
	$flag*=$self->{_output}->{$_};
    }
    if($flag){$self->{_isrun}=0;}else{$self->{_isrun}=1;}
}


1;
