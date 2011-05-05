This forked repository contains [customized extensions](http://wiki.github.com/ThomasBurleson/swiz-framework/) to the Swiz framework; Swiz is a brutally simple micro-architecture for creating Rich Internet Applications with ActionScript 3 and Adobe Flex.

### Differences from the original "upstream" framework:

Default support for bind == true (the upstream setting is FALSE which is a huge source of confusion)

- [Inject(source="sessionModel.endPoint",bind="true")]
- public var endPoint : String = "";

Support for property chains in custom process tags.

- [EventHandler(event="VisualizationEvent.NODE_SELECTED", properties="node.data.serialNumber, autoFit"] 
- [Inject(source="networkModel.currentTopology.manuallyPlacedNodes", bind="true")]

See [Wiki docs](http://github.com/ThomasBurleson/swiz-framework/wiki/MetadataProcessor-Enhancements) for details.

### History:

- 3/13/2011: Fix to support propertyChains in InjectProcessor; e.g. [Inject(source="employeeModel.selectedEmployee.address")] where parts of the chain may be null.
- 9/30/2010: Moved custom extensions to [swiz_extensions_2](http://github.com/ThomasBurleson/swiz-extensions_2) repository
- 9/30/2010: Integrated mainline Swiz features for SwizLogger  
- 9/25/2010: Merged from Swiz GitHub mainline v1.0RC... into this fork on 9/25/2010


## How to Contribute

The Swiz team welcomes contributions to the framework in the form of pull requests. Please note that active development happens in the develop branch, so you should fork from and submit to it, not master.

## Documentation and Reporting Bugs

Swiz does not use GitHub for issue tracking or documentation. Documentation can be found in the [Swiz wiki](http://wiki.swizframework.org/) and bugs and feature requests should be entered in the [Swiz JIRA instance](http://bugs.swizframework.org/)

## Building

You can compile the library .swc file using:

	ant -f ./build/build.xml compile