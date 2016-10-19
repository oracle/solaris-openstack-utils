# Instructions

1. Download Unified Archive images to use for compute instances.  The
   images you use depend on which architecture the compute node is.

SPARC (Patch 24745105):
[Oracle MOS Link](https://support.oracle.com/epmos/faces/PatchResultsNDetails?_adf.ctrl-state=119zeykz9v_9&releaseId=400000110000&requestId=20630501&patchId=24745105&languageId=0&platformId=23&searchdata=%3Ccontext+type%3D%22BASIC%22+search%3D%22%26lt%3BSearch%26gt%3B%0A%26lt%3BFilter+name%3D%26quot%3Bpatch_number%26quot%3B+op%3D%26quot%3Bis%26quot%3B+value%3D%26quot%3B24745105%26quot%3B%2F%26gt%3B%0A%26lt%3BFilter+name%3D%26quot%3Bexclude_superseded%26quot%3B+op%3D%26quot%3Bis%26quot%3B+value%3D%26quot%3Bfalse%26quot%3B%2F%26gt%3B%0A%26lt%3B%2FSearch%26gt%3B%22%2F%3E&_afrLoop=473399882831516)

X86 (Patch 24745114):
[Oracle MOS Link](https://support.oracle.com/epmos/faces/PatchResultsNDetails?_adf.ctrl-state=119zeykz9v_9&releaseId=400000110000&requestId=20630513&patchId=24745114&languageId=0&platformId=267&searchdata=%3Ccontext+type%3D%22BASIC%22+search%3D%22%26lt%3BSearch%26gt%3B%0A%26lt%3BFilter+name%3D%26quot%3Bpatch_number%26quot%3B+op%3D%26quot%3Bis%26quot%3B+value%3D%26quot%3B24745114%26quot%3B%2F%26gt%3B%0A%26lt%3BFilter+name%3D%26quot%3Bexclude_superseded%26quot%3B+op%3D%26quot%3Bis%26quot%3B+value%3D%26quot%3Bfalse%26quot%3B%2F%26gt%3B%0A%26lt%3B%2FSearch%26gt%3B%22%2F%3E&_afrLoop=473361805377861)

Place the images in the ./images directory, the script will automatically
add them to Glance image store during bring-up.
