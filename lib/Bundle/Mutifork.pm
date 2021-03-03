package Bundle::Multifork;
use strict;
use MCE::Hobo;
use MCE::Shared;
use warnings;
use base qw(MyBase::Bio::Root::Root);
use base qw(Bundle::Methods);
use Data::Dumper;
use IPC::Run;
use MyBase::Mysub;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    bless $self,$class;
    return $self;
}

sub cmd_multifork{
    my ($self,$cmd,$fh) =@_;
    
    $fh=*STDOUT, if !$fh;
    my $start_time = time;
    print $fh "CMD: ".scalar(@$cmd)." cmd to be run\n";
    print $fh "CMD: Example $$cmd[0]\n";
    print $fh "TIME: Starts at " . time_string($start_time) . "\n";
    my ($out,$err)=$self->multifork(@$cmd);
    my $end_time = time;
    printf $fh "TIME: Ends at %s (elapsed: %s)\n",
    time_string($end_time), time_elapse_string($start_time, $end_time);
    return ($out,$err);
}

sub run_multifork{
    my($self,$cmd,$opt)=@_;
    print Dumper($opt);
    $self->mkdir("$$opt{dir_log}");
    $self->mkdir("$$opt{dir_log_cmd}");
    my @caller=caller(1);
    print Dumper(@caller);
    $caller[3]=~s/.*://g;
    open my $fh_cmd,">$$opt{dir_log_cmd}/".$caller[3].".cmd";
    open my $fh_out,">$$opt{dir_log_cmd}/".$caller[3].".out";
    open my $fh_err,">$$opt{dir_log_cmd}/".$caller[3].".err";
    
    print $fh_cmd join ("\n",@$cmd)."\n";
    
    $self->isrun? my ($out,$err)=$self->cmd_multifork:print "SKIP: $cmd\n";
    print $fh_out join "\n",@$out;
    print $fh_err join "\n",@$err;

}



sub multifork()
{
    my ($self, @array) = @_;
    my $j=0;
    my $out = MCE::Shared->array();
    my $err = MCE::Shared->array();;
    #print Dumper(scalar(MCE::Hobo->list()));
    while($j<@array){
      LABEL:
      	while((!defined scalar(MCE::Hobo->list()) || scalar(MCE::Hobo->list())<= $self->threads) && $j<@array){
	    MCE::Hobo->create(sub {my @res=$self->system_bash($array[$j]);return (@res,$?,$array[$j]);});
	    $j++;
	}
	
	while ( my $hobo = MCE::Hobo->waitone() ) {
	    my $hoboerr = $hobo->error();
	    my @res = $hobo->result();
	    my $pid = $hobo->pid();
	    #print Dumper(@res);
	    $out->push($res[0]),if $res[0];
	    $err->push($res[1]), if $res[1];
	    #print $res[1];

	    $self->throw("CMD: $res[3] $res[2]"),if $res[2];
	    $self->throw("$hoboerr"),if $hoboerr;
	    goto LABEL, if scalar(MCE::Hobo->list()) <= $self->threads && $j <@array;
	}

    }
    print Dumper(@$out);
    print Dumper(@$err);
    return ($out,$err);
}


1;
