@[if DEVELSPACE]@
if [ $GOPATH ]; then
    export GOPATH="@(CATKIN_DEVEL_PREFIX)/go":"$GOPATH"
else
    export GOPATH="@(CATKIN_DEVEL_PREFIX)/go"
fi
export PATH="$PATH":"@(CATKIN_DEVEL_PREFIX)/go/bin"
@[else]@
if [ $GOPATH ]; then
    export GOPATH="@(CMAKE_INSTALL_PREFIX)/go":"$GOPATH"
else
    export GOPATH="@(CMAKE_INSTALL_PREFIX)/go"
fi
export PATH="$PATH":"@(CMAKE_INSTALL_PREFIX)/go/bin"
@[end if]@
