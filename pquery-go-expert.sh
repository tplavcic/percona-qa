#!/bin/bash
# Created by Roel Van de Paar, Percona LLC
# You can start this script from within a pquery working directory, and it will - every 10 minutes - prepare reducer's, cleanup known issues, and display the results of the current run
# Recommended to run this inside a screen session (alike to pquery-run.sh running in a screen session), so that your hdd/ssd does not run out of space, and so reducer scripts are ready when needed
# This script furthermore modifies some more expert reducer.sh settings which aid in mass-bug handling, though they require some more manual work once reductions are nearing completion;
# FORCE_SKIPV is set to 1
# MULTI_THREADS is set to 3
# MULTI_THREADS_INCREASE is set to 3
# MULTI_THREADS_MAX is set to 9
# The effect of FORCE_SKIPV=1 is that reducer will skip the verify stage, start reduction immediately, using 3 threads (MULTI_THREADS=3), and never increases the set amount of threads (result of
# using FORCE_SKIPV=1). Note that MULTI_THREADS_INCREASE is only relevant for non-FORCE_SKIPV runs, more on why this is changed then below. 
# In short, the big benefit of making these settings is that (assuming you are doing a standard single (client) threaded run) you can easily start 10-20 reducers, as each of those will now 
# only start a maximum of 3 (MULTI_THREADS) threads to reduce each individual trial. There is no possibility for 'runaway' reducers that will take up to MULTI_THREADS_MAX threads (which by default
# means MULTI_THREADS=10, MULTI_THREADS_INCREASE=5 up to the maximum of MULTI_THREADS_MAX=50). Sidenote: While your system may be able to handle one of such reducer's running 50 threads, it would 
# very unlikely handle more then 1-3 of those. In other words, and to summarize, if you start 10 reducers (10 trials being reduced at once), it will only use 30x mysqld (10 reducers, up to 3 
# mysqld's, i.e. MULTI_THREADS, each). 
#  (Note however that if you had a multi-threaded run (i.e. THREADS=x in pquery-run.sh), then there are other considerations; firstly, PQUERY_MULTI would come into play. For true multi-threaded 
#   reduction, you would turn this on. Secondly, turning that on means that PQUERY_MULTI_CLIENT_THREADS also comes into play: the number of client threads PER mysqld. iow: watch server resources)
# Finally, why is MULTI_THREADS_INCREASE being set to 3 instead of the default 5? This brings us also to what is mentioned above: "require some more manual work reductions are nearing completion"
# IOW; when you started 10-20 reducers, a number of them will "just sit there" and not reduce: fine, they need extra work (ref reproducing_and_simplification.txt and check manually in logs what
# is happening etc.). For the reducers that HAVE reduced (hopefully the majority), you'll see that they get "stuck" at around 5 lines remaining. This is normal; due to enabling FORCE_SKIPV, it is
# in an infinite loop to reduce the testcases down to 3 lines (not going to happen in most cases) before it will continue. So, CTRL+C them, open up the matching reducer<nr>.sh file, set the (scroll
# about 3-4 screens down to the #VARMOD# section assuming you used pquery-prep-red.sh) INPUTFILE to "<existing name>_out" (the reduced testcase is named <existing name>_out by reducer, iow it gets 
# the _out suffix) and turn FORCE_SKIPV to 0. Now reducer will first verify the issue (VERIFY stage i.e. V is no longer FOCE skipped now) and then it will go through the normal stages 1,2,3, etc. 
# The likeliness of the VERIFY stage succeeding here is very high; the input testcase is now only 5 lines, it already has reproduced many times, and there is unlikely to be something amiss in the
# now-small SQL which causes non-reproducibilty, most other SQL has been filtered out already. STILL, IT IS POSSIBLE that the issue does not reproduce. Now reducer will stay in MULTI mode and, 
# having started with MULTI_THREADS for the verify stage (sidenote: it would stop being in MULTI mode if all those MULTI threads reproduced the issue in the verify stage, i.e. the issue is not 
# sporadic), and not having found the issue at all (for example), it will add MULTI_THREADS_INCREASE threads (3+3=6) and try again. Again, all this up to a maximum of MULTI_THREADS_MAX, which 
# by default is 50. Now, to reduce the possibility of one starting with 10-20 reducers, then stopping a set of them, setting FORCE_SKIPV=0, and starting to reduce them again to get the optimal 
# testcase, but running into the situation where the VERIFY stage is not able to reproduce the issue at all, and thus cause a set of 'runaway' reducers, MULTI_THREADS_MAX is set to 9, and 
# MULTI_THREADS_INCREASE is set to 3. As MULTI_THREADS_MAX only becomes relevant later in the process, by that time a number of other server resources have likely freed up. IOW, the reason why
# all this is done is to avoid a situation where you are doing x amount of work, then your server hangs, and it's a mess to sort out :) (tip: if this happens, search like this: $ ls ./*_out )
#  (Sidenote: in the case where reduced does detect the issue but not in all the MULTI_THREADS threads, it will assume the issue sporadic, and hence a situation quite alike to FORCE_SKIPV=1
#   is auto-set. In that case, go CTRL+_C and be happy with the thus-far (~5 lines) testcase, and post it to a bug using the created <epoch> scripts (_init, _start, _cl, _run, _run_pquery etc.) 
#   - just use the generated tarball and copy in the <epoch>_how_to_reproduce.txt text into the bug report - sporadic issues are perhaps best handled like this as the reproducer scrips are a 
#   neat/tidy way of reproducing the issue for the developers by only change the base directory in <epoch>_mybase) 
# Hope that all of the above makes sense :), ping me if it does not :)

# Internal variables
SCRIPT_PWD=$(cd `dirname $0` && pwd)

while(true); do 
  ~/percona-qa/pquery-prep-red.sh
  ~/percona-qa/pquery-clean-known.sh
  if [ $(ls reducer*.sh 2>/dev/null | wc -l) -gt 0 ]; then
    sed -i "s|^FORCE_SKIPV=0|FORCE_SKIPV=1|" reducer*.sh
    sed -i "s|^MULTI_THREADS=[0-9]\+|MULTI_THREADS=3|" reducer*.sh
    sed -i "s|^MULTI_THREADS_INCREASE=[0-9]\+|MULTI_THREADS_INCREASE=3|" reducer*.sh
    sed -i "s|^MULTI_THREADS_MAX=[0-9]\+|MULTI_THREADS_MAX=9|" reducer*.sh
  fi
  ~/percona-qa/pquery-results.sh
  sleep 600
done
