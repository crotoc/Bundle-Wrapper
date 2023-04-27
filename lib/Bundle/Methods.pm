package Bundle::Methods;
use strict;
use warnings;
use parent qw(Bundle::Bio::Root::Root);
use Data::Dumper;
use IPC::Run;
use String::Random;
use B qw( svref_2object );
use File::Path qw(make_path remove_tree);
use IPC::Cmd qw#can_run#;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    bless $self,$class;
    $self->setMethod("threads"=>5);
    $self->setMethod("chunk_size"=>1);
    return $self;
}

sub setMethod{
    my ($self,%args)=@_;
    my @keys=keys %args;
    ##print Dumper %args;
    $self->_set_from_args(\%args,
     			  -methods => \@keys,
     			  -create => 1
     	); 
}


sub opt_print{
    my ($self,$hash,$fh,$fmt_hash)= @_;
    $fh=*STDOUT,if !$fh;
    if(!$fmt_hash){
	$fmt_hash->{a} = 10 if !defined $fmt_hash->{a};
	$fmt_hash->{b} = 15 if !defined $fmt_hash->{b};
	$fmt_hash->{c} = 5  if !defined $fmt_hash->{c};
	$fmt_hash->{d} = 40 if !defined $fmt_hash->{d};
    }
    foreach my $key (sort keys %$hash) {
	if(ref $hash->{$key} eq 'ARRAY'){$hash->{$key}=join ",",@{$hash->{$key}}}
	print $fh " " x $fmt_hash->{a};
	if(!defined $hash->{$key}){$hash->{$key}=""}
	printf $fh "%-$fmt_hash->{b}s %s %-$fmt_hash->{d}s\n", "-$key", " " x $fmt_hash->{c},$hash->{$key};
    }

}

sub time_string
{
    my $self = shift;
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime;
    return sprintf('%04d-%02d-%02d %02d:%02d:%02d',
		   $year + 1900, $mon + 1, $mday, $hour, $min, $sec);
}

sub test_file{
    my $self = shift;
    my @file = @_;
    my $flag;
    foreach (@file){
	if (-e $_){ print STDERR "TEST: $_ existed\n"; $flag=1;}
	else {print STDERR "TEST: $_ not existed\n";return 0;}
    }
    return $flag;
}

sub test_rlt_file{

    my @file = @_;
    my $flag;
    foreach (@file){
	if (-e $_){ print STDERR "TEST: $_ existed\n"; $flag=1;}
	else {print STDERR "TEST: $_ not existed\n";return 0;}
    }
    return $flag;
}


sub time_elapse_string
{
    my ($self,$start_time, $end_time) = @_;
    my $elapsed_time = $end_time - $start_time;
    my $time_elapse_text = '';
    if ($elapsed_time >= 86400) {
	$time_elapse_text .= int($elapsed_time / 86400) . 'd ';
	$elapsed_time %= 86400;
    }
    if ($time_elapse_text or $elapsed_time >= 3600) {
	$time_elapse_text .= int($elapsed_time / 3600) . 'h ';
	$elapsed_time %= 3600;
    }
    if ($time_elapse_text or $elapsed_time >= 60) {
	$time_elapse_text .= int($elapsed_time / 60) . 'm ';
	$elapsed_time %= 60;
    }
    if ($time_elapse_text eq '' or $elapsed_time > 0) {
	$time_elapse_text .= $elapsed_time . 's ';
    }
    $time_elapse_text =~ s/\s$//g;
    return $time_elapse_text;
}

sub cmd_go{
    my ($self,$cmd,$fh,$ignore) =@_;
    $fh=*STDERR, if !$fh;
    print $fh "CMD: $cmd\n";
    my $start_time = time;
    print $fh "TIME: Starts at " . time_string($start_time) . "\n";
    my $hash=$self->system_bash($cmd);
    $hash->{success}=$?;
    $hash->{cmd}=$cmd;

    if($hash->{success}){$self->clean_err_output;if(!$ignore){die "not sucessfull: $hash->{stderr}\n";}else{warn("not sucessfull: $hash->{stderr}\n")}}
    my $end_time = time;
    printf $fh "TIME: Ends at %s (elapsed: %s)\n",
    $self->time_string($end_time), $self->time_elapse_string($start_time, $end_time);
    return $hash;
}

sub cmd_go_nolog{
    my ($self,$cmd,$fh,$ignore) =@_;
    $fh=*STDOUT, if !$fh;
    print $fh "CMD: $cmd\n";
    my $start_time = time;
    print $fh "TIME: Starts at " . time_string($start_time) . "\n";
    my $hash=$self->system_bash($cmd);
    $hash->{success}=$?;
    $hash->{cmd}=$cmd;

    if($hash->{success}){$self->clean_err_output;if(!$ignore){die "not sucessfull: $hash->{stderr}\n";}else{warn("not sucessfull: $hash->{stderr}\n")}}
    my $end_time = time;
    printf $fh "TIME: Ends at %s (elapsed: %s)\n",
    $self->time_string($end_time), $self->time_elapse_string($start_time, $end_time);
    return $hash;
}


sub clean_err_output{
    my ($self )=shift;
    foreach (keys %{$self->{_output}}){
	my $cmd = "rm $_";
	$self->system_bash($cmd);
    }
}

sub step_print{
    my ($self,$str)= @_;
    print STDERR "\nSTEP: $str\n";
    $self->{_step} = $str;
}

sub system_bash {
    my $self = shift;
    my ($in,$stdout,$stderr);
    my @args = ("bash", "-c", shift );
    my $hash;
    IPC::Run::run \@args,\$in,\$hash->{stdout},\$hash->{stderr};
    #print $err;
    #print Dumper($stdout);
    #print Dumper($stderr);
    
    return $hash;
}


sub run{
    my($self,$cmd)=@_;
    my $fh_log=$self->log_fh();
    print {$fh_log->{cmd}} $cmd."\n";

    $self->isrun? my $out=$self->cmd_go($cmd):print STDERR "SKIP: $cmd\n";

    #print Dumper $self;
    if($out){
	print {$fh_log->{out}} "CMD:$out->{cmd}\nOUT:$out->{stdout}\n";
	print {$fh_log->{err}} "CMD:$out->{cmd}\nERR:$out->{stderr}\n";        
    }
    $out

}

sub log_last{
    my($self)=@_;
    #print Dumper($self);
    $self->system_bash("rm -rf ${$self->opt}{dir_log}/last"), if -e "`${$self->opt}{dir_log}/last";
    $self->mkdir("${$self->opt}{dir_log}/last");
    $self->system_bash("cp ${$self->opt}{dir_log_cmd}/* ${$self->opt}{dir_log}/last"), if exists ${$self->opt}{dir_log_cmd};
}

sub log_fh{
    my($self)=@_;
    $self->throw("Must include \$opt{time}=Bundle::Wrapper->date in script;"), if !${$self->opt}{time};
    
    my $string_gen = String::Random->new;
    ${$self->opt}{dir_log_cmd}=${$self->opt}{dir_log}."/${$self->opt}{time}"."-". $string_gen->randpattern("CCCCCCCC"), if !${$self->opt}{dir_log_cmd};
    $self->system_bash("mkdir -p ${$self->opt}{dir_log_cmd}");
    my $i = 0;
    
    my @caller;
    while ( (my @call_details = (caller($i++))) ){
	## print STDERR $call_details[1].":".$call_details[2]." in function ".$call_details[3]."\n";
	@caller = @call_details;
    }

    my $fh;
    my $step = $caller[3];
    if($step=~/^main/){
	$step=~s/.*:://g;
    }else{
	if($self->{_step}){
	    $step = $self->{_step};
	    $step =~s/ /_/g;
	}else{
	    $step=~s/.*:://g;
	}
    }

    ## print Dumper ${$self->opt}{dir_log_cmd}."/".$step.".cmd";
    open $fh->{cmd},">>",${$self->opt}{dir_log_cmd}."/".$step.".".$self->date.".cmd" or die "Can't open \$fh->{cmd}";
    open $fh->{out},">>",${$self->opt}{dir_log_cmd}."/".$step.".".$self->date.".out";
    open $fh->{err},">>",${$self->opt}{dir_log_cmd}."/".$step.".".$self->date.".err";
    return ($fh);
}

sub log_print{
    my($self,$cmd,$fh_log);
    if(!$fh_log){return "0";}
    if(ref($cmd) eq "ARRAY"){
	print $fh_log join ("\n",@$cmd)."\n";
    }
    elsif(ref($cmd) eq "SCALAR"){
	print $fh_log $cmd."\n";
    }
    else{
	$self->throw("wrong format log print")
    }
    
}

sub date{
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my @abbr = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my @abbr_num = qw(01 02 03 04 05 06 07 08 09 10 11 12);
    $year += 1900;
    $mon  += 1;
    my @out;
    push @out,(sprintf("%s%02d%02d",$year,$mon,$mday),sprintf("%02d%02d%02d",$hour,$min,$sec));
    return join "-",@out;
}


sub mkdir{
    my ($self)=shift;
    my @dir = @_;
    foreach(@dir){
	my $cmd = "mkdir -p $_";
	if(! -e $_ ){
	    $self->cmd_go_nolog("$cmd",*STDERR,1);
	}
	else{
	    if(-d $_){ print STDERR "SKIP: $cmd\n";}
	    else{$self->throw("existed a file name called $_");}
	}
    }
}

sub mkpath{
    my ($self)=shift;
    my @dir = @_;
    foreach(@dir){
	if(! -e $_ ){
	    $self->make_path($_);
	}
	else{
	    if(-d $_){ print STDERR "SKIP: mkdir $_\n";}
	    else{$self->throw("existed a file name called $_");}
	}
    }
}


sub get{
    my ($self,$str)=@_;
    return $self->{"_$str"};
}


sub getPrefix{
    my ($self,$str,$del)=@_;
    if(! defined $del){
	$del = "\\.\\w+?"
    }
    ## print Dumper $del;
    $str=~s/$del$//g;
    ## print Dumper $str;
    $str=~s/.*\///g;
    return $str;
}

sub getFilename{
    my ($self,$str)=@_;
    $str=~s/.*\///g;
    return $str;
}

sub getFiledir{
    my ($self,$str)=@_;

    if($str!~/\//){
	$str="./"
    }else{
	$str=~s/(.*\/).*/$1/g;
    }
    return $str;

}



sub getSub {
    my ($self,$pkg_name) = @_;
    my $pkg = do { no strict 'refs'; \%{ $pkg_name . '::' } };
    my $sub;
    my @sub;
    #print Dumper $pkg;
    foreach my $name (keys %$pkg) {
	#print Dumper $name;
	if(defined &{"main::$name"}){
	    #print Dumper $name;
	    my $glob = $pkg->{$name};
	    my $code = *$glob{CODE}
	    or next;
	    my $cv = svref_2object($code);
	    my $orig_pkg_name = $cv->GV->STASH->NAME;
	    next if $orig_pkg_name ne "main" || $name=~/^_/;
	    push @sub,$name;
	    #print Dumper $orig_pkg_name;
	}
	
    }
    $sub = join ",",@sub;
    return $sub
}


sub clean{
    my ($self,@dir)=@_;
    foreach (@dir){
	if(-e $_){
	    $self->step_print("rm file/dir in $_");
	    my $cmd="rm -rf $_";
	    $self->cmd_go($cmd);
	}
    }
}


sub sendmail()
{
    my ($class,$command_line,$email) = @_;
    
    
    if ($email)
    {
	my $from="vmpsched\@vmpsched.vampire";
	my $to="$email";
	my $subject="An error";

	my $sendmailpath="/usr/sbin/sendmail";

	my $message = "An error has occurred processing your job, see below.\n$command_line\n\nfrom cgg lab\n";

	open (SENDMAIL, "| $sendmailpath -t") or die "Cannot open $sendmailpath: $!";

	print SENDMAIL "Subject: $subject\n";
	print SENDMAIL "From: $from\n";
	print SENDMAIL "To: $to\n\n";

	print SENDMAIL "$message";

	close (SENDMAIL);
    }
}


####################################################################
##                   Format Output function
####################################################################
sub getStrByKeysHash
{
    my ($self,$keys) = @_;
    print Dumper $keys;
    my @str;
    map {exists $self->{"$_"}?push @str,$self->{"$_"}:push @str,"";}  @$keys;
    return join ";",@str;
}

sub getStrByKeysSepHash
{
    my ($self,$keys,$sep) = @_;
    $sep=";",if !$sep;
    my @str;
    map {exists $self->{"$_"}?push @str,$self->{"$_"}:push @str,"";}  @$keys;
    #print Dumper(scalar(@str));
    return join $sep,@str;
}


sub getArrayByKeysHash
{
    my ($self,$keys) = @_;
    my @str;
    map {exists $self->{"$_"}?push @str,$self->{"$_"}:push @str,"";} @$keys;
    return \@str;
}

sub getTabByKeysHash
{
    my ($self,$keys) = @_;
    my @str;
    map {push @str,$self->{"$_"}} @$keys;
    return join "\t",@str;
}


####################################################################
##                             Other
####################################################################
sub prompt{
    my ($self,$mode)=@_;
    if($mode eq "yesorno"){
	while(my $prompt=<STDIN>){
	    chomp($prompt);
	    if(!$prompt){return 1;}
	    elsif($prompt=~/y/ && $prompt!~/n/){
		return 1;
	    }
	    else{return 0;}
	}
    }
    elsif($mode eq "reply"){
	while(my $prompt=<STDIN>){
	    chomp($prompt);
	    if(!$prompt){next;}
	    else{return $prompt;}
	}
    }
    else{
	exit("wrong mode for subroutine promp\n");
    }

}


sub prompt_option{
    my ($self,$x) = @_;
    my $min = min($#$x,15);
    map {print STDERR $_+1,"\t",$$x[$_],"\n"} 0..$min;
    print STDERR "输入:\t";
    while( my $i = &prompt("reply")){
	if(looks_like_number($i) && $i <=@$x){
	    my ($key,$value) = split/\s*\t\s*/,$$x[$i-1];
	    print STDERR "你选中的是:\t$key\n";
	    return $key;
	}
	elsif(!looks_like_number($i)){
	    print STDERR "new entry\n";
	    return $i;
	}
	elsif($i > @$x){
	    print STDERR "input number too big\n";
	    next;
	}
    }
}

sub counting{
    my ($self,$file) = @_;
    print "\nSUBSTEP: Counting\n";
    if($self->test_file($file)){
	my $cmd="wc -l $file";
	$self->cmd_go($cmd);
    }
    else{ $self->throw("No such file;")}
    print "done\n\n";
} 

sub colstr2array
{
    my ($class,$str) = @_;
    my @array;
    if($str!~/,|-/){
	push @array,$str
    }
    elsif($str=~/-/ && $str!~/,/){
	@array = $class->scale2array($str);
    }
    elsif($str=~/,/ && $str!~/-/){
	@array = split/,/,$str;
    }
    else
    {
	my @tmp = split/,/,$str;
	for(@tmp){
	    if(/-/){
		push @array,$class->scale2array($_);
	    }
	    else
	    {
		push @array,$_;
	    }
	}	
    }
    return @array;
}

sub grouphash{
    #Input group or map file, return group-wise Hashes
    my $class = shift;
    my @q = @{$_[0]};
    my $format = $_[1];
    my $col = $_[2];
    my %a;
    my %b;
    #print @q;

    foreach my $query(@q){
        my $group;
        my $chr;
        my $pos;
        my $freq;
        
	if($query!~/#/){
	    if($format eq "map"){
		($group,$chr,$pos,$freq) = split/[\t:]/, $query;
		$a{"$chr\t$group"}++;
		#print "$query\t".$a{"$chr\t$group"},"\n";
		if($a{"$chr\t$group"}>=1){
		    push @{$b{"$chr\t$group"}},$query."\n";
		}
	    }
	    elsif($format eq "group"){
		($chr,$pos,$group) = split/\t/, $query;
		$a{"$chr\t$group"}++;
		#print "$query\t".$a{"$chr\t$group"},"\n";
		if($a{"$chr\t$group"}>=1){
		    push @{$b{"$chr\t$group"}},$query."\n";
		}
	    }
	    elsif($format eq "bycol"){
		my @temp = split/\t/,$query;
		$group = $temp[$col-1];
		$a{"$group"}++;
		#print "$query\t".$a{"$chr\t$group"},"\n";
		if($a{"$group"}>=1){
		    push @{$b{"$group"}},$query."\n";
		}
	    }
	    else{
		die "Please input right format";
	    }
	    
	}
    }
    return %b;
}



1;

