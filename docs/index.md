# PowerShell-Docker

Hello!
This is the main documentation page for PowerShell-Docker, so here you can find some helpful details for different questions.

## Image Purpose

These images are built so that PowerShell users can run the program in a containerized environment - see [this article](https://opensource.com/resources/what-docker) for what Docker is, and some basic pros and cons.
Another reason Docker containers can be important is space. These images are purposefully small, and may require extra libraries to be installed for your use case.

### `test-dep` Images

Some images have a sub image (called `test-dep` images). These images are intended to allow running tests in [Azure DevOps](https://azure.microsoft.com/en-us/product-categories/devops/) for PowerShell.

## Development

See the [development docs](./development.md)
