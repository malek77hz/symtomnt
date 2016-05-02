# symtomnt
Bash script to take all symlink (on windows docker shared folders) and creeate mounted drives

SYMLINK 2 MOUNT
v1.0 May 2nd 2016
by Malek Nasser

Bash script to search for all symlinks and
replace with dirs + suffix then mount binds the symlink location

This is specifily to deal with Docker on Windows and its problem
with symlinks on host/containers shared drives
https://forums.docker.com/t/symlinks-on-shared-volumes-not-supported/9288

Its hopefully something that will not be needed in the future but this may
still be useful 

At the moment this just deals with Dirs but could be made to work with actual files
in which case instead of making a dir and mounting it would simply copy the file

THe way this works is by searching out all symlinks the docker/vm combo
has broken, finding out where they are pointing and making a new dir + suffix
then simply mount binding the location

The reason I chose this method instead of 
1) Simply copying the dirs and 
2) Using the same name as the symlink
is that it does not actually change anything that `git` can see
However it will mean you need code to trigger when you are in symlink mode
and mount mode... adjusting name slightly in each case

As the links are broken instead of finding symlinks with
<nix>
find . -type l | while read -r filename ; do
we have to use
<win/docker>
egrep -lir "(\!\<symlink\>)" . | while read -r filename ; do

Also instead of simply using readfile to get location of the symlink
We have to use a convoluted method os reading the file, wiping the <symlink> text
wiping any junk windows crap etc

ALso when running the docker container you will have to run with --privileged

docker run --name %NAME% -it --privileged -v %%localdir%%:%%linkdir%% %%imagename%%
