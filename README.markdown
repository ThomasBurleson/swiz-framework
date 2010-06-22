This forked repository contains [customized extensions](http://wiki.github.com/ThomasBurleson/swiz-framework/) to the Swiz framework; Swiz is a brutally simple micro-architecture for creating Rich Internet Applications with ActionScript 3 and Adobe Flex.

Custom extension include the LogProcessor, DeepLinkeProcessor, and the AsyncInterceptor; and refactored LoggerRegistry.
Also includes modified (slightly) ThunderBoltAS3 classes for logging to FireBug console.

## Building

You can compile the library .swc file using:

	ant -f ./build/build.xml compile