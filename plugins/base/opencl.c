#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <opencl.h>
#include "lua.h"
#include "lauxlib.h"
#include "ljitauxlib.h"

const char* errtostr(int err) {
	switch (err) {
		case CL_SUCCESS:
			return "SUCCESS";
		break;
		case CL_DEVICE_NOT_FOUND:
			return "DEVICE_NOT_FOUND";
		break;
		case CL_DEVICE_NOT_AVAILABLE:
			return "DEVICE_NOT_AVAILABLE";
		break;
		case CL_COMPILER_NOT_AVAILABLE:
			return "COMPILER_NOT_AVAILABLE";
		break;
		case CL_MEM_OBJECT_ALLOCATION_FAILURE:
			return "MEM_OBJECT_ALLOCATION_FAILURE";
		break;
		case CL_OUT_OF_RESOURCES:
			return "OUT_OF_RESOURCES";
		break;
		case CL_OUT_OF_HOST_MEMORY:
			return "OUT_OF_HOST_MEMORY";
		break;
		case CL_PROFILING_INFO_NOT_AVAILABLE:
			return "PROFILING_INFO_NOT_AVAILABLE";
		break;
		case CL_MEM_COPY_OVERLAP:
			return "MEM_COPY_OVERLAP";
		break;
		case CL_IMAGE_FORMAT_MISMATCH:
			return "IMAGE_FORMAT_MISMATCH";
		break;
		case CL_IMAGE_FORMAT_NOT_SUPPORTED:
			return "IMAGE_FORMAT_NOT_SUPPORTED";
		break;
		case CL_BUILD_PROGRAM_FAILURE:
			return "BUILD_PROGRAM_FAILURE";
		break;
		case CL_MAP_FAILURE:
			return "MAP_FAILURE";
		break;
		case CL_MISALIGNED_SUB_BUFFER_OFFSET:
			return "MISALIGNED_SUB_BUFFER_OFFSET";
		break;
		case CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST:
			return "EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST";
		break;
		case CL_COMPILE_PROGRAM_FAILURE:
			return "COMPILE_PROGRAM_FAILURE";
		break;
		case CL_LINKER_NOT_AVAILABLE:
			return "LINKER_NOT_AVAILABLE";
		break;
		case CL_LINK_PROGRAM_FAILURE:
			return "LINK_PROGRAM_FAILURE";
		break;
		case CL_DEVICE_PARTITION_FAILED:
			return "DEVICE_PARTITION_FAILED";
		break;
		case CL_KERNEL_ARG_INFO_NOT_AVAILABLE:
			return "KERNEL_ARG_INFO_NOT_AVAILABLE";
		break;
		case CL_INVALID_VALUE:
			return "INVALID_VALUE";
		break;
		case CL_INVALID_DEVICE_TYPE:
			return "INVALID_DEVICE_TYPE";
		break;
		case CL_INVALID_PLATFORM:
			return "INVALID_PLATFORM";
		break;
		case CL_INVALID_DEVICE:
			return "INVALID_DEVICE";
		break;
		case CL_INVALID_CONTEXT:
			return "INVALID_CONTEXT";
		break;
		case CL_INVALID_QUEUE_PROPERTIES:
			return "INVALID_QUEUE_PROPERTIES";
		break;
		case CL_INVALID_COMMAND_QUEUE:
			return "INVALID_COMMAND_QUEUE";
		break;
		case CL_INVALID_HOST_PTR:
			return "INVALID_HOST_PTR";
		break;
		case CL_INVALID_MEM_OBJECT:
			return "INVALID_MEM_OBJECT";
		break;
		case CL_INVALID_IMAGE_FORMAT_DESCRIPTOR:
			return "INVALID_IMAGE_FORMAT_DESCRIPTOR";
		break;
		case CL_INVALID_IMAGE_SIZE:
			return "INVALID_IMAGE_SIZE";
		break;
		case CL_INVALID_SAMPLER:
			return "INVALID_SAMPLER";
		break;
		case CL_INVALID_BINARY:
			return "INVALID_BINARY";
		break;
		case CL_INVALID_BUILD_OPTIONS:
			return "INVALID_BUILD_OPTIONS";
		break;
		case CL_INVALID_PROGRAM:
			return "INVALID_PROGRAM";
		break;
		case CL_INVALID_PROGRAM_EXECUTABLE:
			return "INVALID_PROGRAM_EXECUTABLE";
		break;
		case CL_INVALID_KERNEL_NAME:
			return "INVALID_KERNEL_NAME";
		break;
		case CL_INVALID_KERNEL_DEFINITION:
			return "INVALID_KERNEL_DEFINITION";
		break;
		case CL_INVALID_KERNEL:
			return "INVALID_KERNEL";
		break;
		case CL_INVALID_ARG_INDEX:
			return "INVALID_ARG_INDEX";
		break;
		case CL_INVALID_ARG_VALUE:
			return "INVALID_ARG_VALUE";
		break;
		case CL_INVALID_ARG_SIZE:
			return "INVALID_ARG_SIZE";
		break;
		case CL_INVALID_KERNEL_ARGS:
			return "INVALID_KERNEL_ARGS";
		break;
		case CL_INVALID_WORK_DIMENSION:
			return "INVALID_WORK_DIMENSION";
		break;
		case CL_INVALID_WORK_GROUP_SIZE:
			return "INVALID_WORK_GROUP_SIZE";
		break;
		case CL_INVALID_WORK_ITEM_SIZE:
			return "INVALID_WORK_ITEM_SIZE";
		break;
		case CL_INVALID_GLOBAL_OFFSET:
			return "INVALID_GLOBAL_OFFSET";
		break;
		case CL_INVALID_EVENT_WAIT_LIST:
			return "INVALID_EVENT_WAIT_LIST";
		break;
		case CL_INVALID_EVENT:
			return "INVALID_EVENT";
		break;
		case CL_INVALID_OPERATION:
			return "INVALID_OPERATION";
		break;
		case CL_INVALID_GL_OBJECT:
			return "INVALID_GL_OBJECT";
		break;
		case CL_INVALID_BUFFER_SIZE:
			return "INVALID_BUFFER_SIZE";
		break;
		case CL_INVALID_MIP_LEVEL:
			return "INVALID_MIP_LEVEL";
		break;
		case CL_INVALID_GLOBAL_WORK_SIZE:
			return "INVALID_GLOBAL_WORK_SIZE";
		break;
		case CL_INVALID_PROPERTY:
			return "INVALID_PROPERTY";
		break;
		case CL_INVALID_IMAGE_DESCRIPTOR:
			return "INVALID_IMAGE_DESCRIPTOR";
		break;
		case CL_INVALID_COMPILER_OPTIONS:
			return "INVALID_COMPILER_OPTIONS";
		break;
		case CL_INVALID_LINKER_OPTIONS:
			return "INVALID_LINKER_OPTIONS";
		break;
		case CL_INVALID_DEVICE_PARTITION_COUNT:
			return "INVALID_DEVICE_PARTITION_COUNT";
		break;
	}
	return "UNKNOWN";
}

void checkerr(lua_State* L,cl_int err) {
	if (err!=CL_SUCCESS) {
		luaL_error(L,"%s",errtostr(err));
	}
}

typedef struct {
	cl_device_id device_id;
	cl_context context;
	cl_command_queue commands;
	unsigned int refcount;
} lclGpu;

static int lcl_gpu_index(lua_State* L) {
	lclGpu* state=*(lclGpu**)luaL_checkudata(L,1,"opencl.gpu");
	if (lua_isstring(L,2)) {
		const char* n=luaL_checkstring(L,2);
		size_t len;
		char out[512];
		if (!strcmp(n,"extentions")) {
			cl_int err=clGetDeviceInfo(state->device_id,CL_DEVICE_EXTENSIONS,sizeof(out),(void*)out,&len);
			checkerr(L,err);
			lua_pushstring(L,out);
			return 1;
		} else if (!strcmp(n,"name")) {
			cl_int err=clGetDeviceInfo(state->device_id,CL_DEVICE_NAME,sizeof(out),(void*)out,&len);
			checkerr(L,err);
			lua_pushstring(L,out);
			return 1;
		} else if (!strcmp(n,"device_version")) {
			cl_int err=clGetDeviceInfo(state->device_id,CL_DEVICE_VERSION,sizeof(out),(void*)out,&len);
			checkerr(L,err);
			lua_pushstring(L,out);
			return 1;
		} else if (!strcmp(n,"driver_version")) {
			cl_int err=clGetDeviceInfo(state->device_id,CL_DRIVER_VERSION,sizeof(out),(void*)out,&len);
			checkerr(L,err);
			lua_pushstring(L,out);
			return 1;
		} else if (!strcmp(n,"vendor")) {
			cl_int err=clGetDeviceInfo(state->device_id,CL_DEVICE_VENDOR,sizeof(out),(void*)out,&len);
			checkerr(L,err);
			lua_pushstring(L,out);
			return 1;
		} else if (!strcmp(n,"profile")) {
			cl_int err=clGetDeviceInfo(state->device_id,CL_DEVICE_PROFILE,sizeof(out),(void*)out,&len);
			checkerr(L,err);
			lua_pushstring(L,out);
			return 1;
		} else if (!strcmp(n,"memsize")) {
			cl_ulong out;
			cl_int err=clGetDeviceInfo(state->device_id,CL_DEVICE_GLOBAL_MEM_SIZE,sizeof(out),&out,&len);
			checkerr(L,err);
			lua_pushnumber(L,out);
			return 1;
		}
	}
	lua_pushnil(L);
	return 1;
}

void lcl_gpu_tryCollect(lclGpu* state) {
	if (state->refcount<1) {
		if (state->device_id) {
			clReleaseDevice(state->device_id);
		}
		if (state->context) {
			clReleaseContext(state->context);
		}
		if (state->commands) {
			clReleaseCommandQueue(state->commands);
		}
		free(state);
	}
}

static int lcl_gpu_gc(lua_State *L) {
	lclGpu* state=*(lclGpu**)luaL_checkudata(L,1,"opencl.gpu");
	state->refcount--;
	lcl_gpu_tryCollect(state);
	return 0;
}

extern int lcl_initGpu(lua_State* L) {
	lclGpu** statePtr=(lclGpu**)lua_newuserdata(L,sizeof(lclGpu*));
	lclGpu* state=(lclGpu*)calloc(sizeof(lclGpu),1);
	*statePtr=state;
	state->refcount++;
	if (luaL_newmetatable(L,"opencl.gpu")) {
		lua_pushstring(L,"__index");
		lua_pushcfunction(L,lcl_gpu_index);
		lua_settable(L,-3);
		lua_pushstring(L,"__gc");
		lua_pushcfunction(L,lcl_gpu_gc);
		lua_settable(L,-3);
	}
	lua_setmetatable(L,-2);
	
	int err=clGetDeviceIDs(NULL,CL_DEVICE_TYPE_GPU,1,&state->device_id,NULL);
	if (err!=CL_SUCCESS) {
		luaL_error(L,"%s: Failed to create a device group!",errtostr(err));
	}
	state->context=clCreateContext(0,1,&state->device_id,NULL,NULL,&err);
	if (!state->context) {
		luaL_error(L,"%s: Failed to create a compute context!",errtostr(err));
	}
	state->commands=clCreateCommandQueue(state->context,state->device_id,0,&err);
	if (!state->commands) {
		luaL_error(L,"%s: Failed to create a command commands!",errtostr(err));
	}
	return 1;
}

typedef struct {
	lclGpu* gpu;
	cl_program program;
	cl_kernel kernel;
	cl_uint dims;
	size_t maxlocal;
	size_t globalsizes[4];
	size_t localsizes[4];
	unsigned int refcount;
} lclCode;

static int lcl_code_index(lua_State* L) {
	lclCode* state=*(lclCode**)luaL_checkudata(L,1,"opencl.code");
	if (lua_isstring(L,2)) {
		const char* n=luaL_checkstring(L,2);
		if (!strcmp(n,"threads")) {
			lua_pushnumber(L,state->globalsizes[0]);
			return 1;
		}
	}
	lua_pushnil(L);
	return 1;
}

int min(int a,int b) {
	return a<b?a:b;
}

static int lcl_code_newindex(lua_State* L) {
	lclCode* state=*(lclCode**)luaL_checkudata(L,1,"opencl.code");
	if (lua_isstring(L,2)) {
		const char* n=luaL_checkstring(L,2);
		if (!strcmp(n,"threads")) {
			state->globalsizes[0]=luaL_checknumber(L,3);
			state->localsizes[0]=min(state->maxlocal,state->globalsizes[0]);
			return 1;
		}
	}
	lua_pushnil(L);
	return 1;
}

void lcl_code_tryCollect(lclCode* state) {
	if (state->refcount<1) {
		if (state->program) {
			clReleaseProgram(state->program);
		}
		if (state->kernel) {
			clReleaseKernel(state->kernel);
		}
		free(state);
	}
}

static int lcl_code_gc(lua_State *L) {
	lclCode* state=*(lclCode**)luaL_checkudata(L,1,"opencl.code");
	state->gpu->refcount--;
	lcl_gpu_tryCollect(state->gpu);
	state->refcount--;
	lcl_code_tryCollect(state);
	return 0;
}

extern int lcl_compile(lua_State* L) {
	lclGpu* gpustate=*(lclGpu**)luaL_checkudata(L,1,"opencl.gpu");
	const char* src[1];
	src[0]=luaL_checkstring(L,2);
	lclCode** statePtr=(lclCode**)lua_newuserdata(L,sizeof(lclCode*));
	lclCode* state=(lclCode*)calloc(sizeof(lclCode),1);
	*statePtr=state;
	state->gpu=gpustate;
	state->globalsizes[0]=1;
	state->localsizes[0]=1;
	state->dims=1;
	gpustate->refcount++;
	state->refcount++;
	if (luaL_newmetatable(L,"opencl.code")) {
		lua_pushstring(L,"__index");
		lua_pushcfunction(L,lcl_code_index);
		lua_settable(L,-3);
		lua_pushstring(L,"__newindex");
		lua_pushcfunction(L,lcl_code_newindex);
		lua_settable(L,-3);
		lua_pushstring(L,"__gc");
		lua_pushcfunction(L,lcl_code_gc);
		lua_settable(L,-3);
	}
	lua_setmetatable(L,-2);
	int err;
	state->program=clCreateProgramWithSource(gpustate->context,1,src,NULL,&err);
	if (!state->program) {
		luaL_error(L,"%s: Failed to create compute program!",errtostr(err));
	}
	err=clBuildProgram(state->program,0,NULL,NULL,NULL,NULL);
	if (err!=CL_SUCCESS) {
		size_t len;
		char buffer[8192];
		clGetProgramBuildInfo(state->program,gpustate->device_id,CL_PROGRAM_BUILD_LOG,sizeof(buffer),buffer,&len);
		luaL_error(L,"%s: Failed to build program executable! %s",errtostr(err),buffer);
	}
	state->kernel=clCreateKernel(state->program,"main",&err);
	if (!state->kernel || err != CL_SUCCESS) {
		luaL_error(L,"%s: Failed to create compute kernel!",errtostr(err));
	}
	err=clGetKernelWorkGroupInfo(state->kernel,gpustate->device_id,CL_KERNEL_WORK_GROUP_SIZE,sizeof(state->maxlocal),&state->maxlocal,NULL);
	if (err != CL_SUCCESS) {
		luaL_error(L,"%s: Failed to retrieve kernel work group info!",errtostr(err));
	}
	return 1;
}

typedef struct {
	lclGpu* gpu;
	size_t size;
	int ctype;
	cl_mem buffer;
	unsigned int refcount;
} lclBuffer;

static int lcl_buffer_tryCollect(lclBuffer* state) {
	if (state->refcount<1) {
		clReleaseMemObject(state->buffer);
	}
	return 0;
}

static int lcl_buffer_gc(lua_State *L) {
	lclBuffer* state=*(lclBuffer**)luaL_checkudata(L,1,"opencl.buffer");
	state->gpu->refcount--;
	lcl_gpu_tryCollect(state->gpu);
	state->refcount--;
	lcl_buffer_tryCollect(state);
	return 0;
}

static int lcl_buffer_read(lua_State *L) {
	lclBuffer* state=*(lclBuffer**)luaL_checkudata(L,1,"opencl.buffer");
	void *o;
	if (state->ctype) {
		o=luaL_pushtcdata(L,NULL,state->size,state->ctype);
	} else {
		char type[32];
		snprintf(type,32,"char[%i]",(int)state->size);
		o=luaL_pushcdata(L,NULL,state->size,type);
	}
	clEnqueueReadBuffer(state->gpu->commands,state->buffer,CL_TRUE,0,state->size,o,0,NULL,NULL);  
	return 1;
}

static int lcl_buffer_write(lua_State *L) {
	lclBuffer* state=*(lclBuffer**)luaL_checkudata(L,1,"opencl.buffer");
	lclGpu* gpustate=state->gpu;
	size_t size;
	void* data;
	if (lua_isstring(L,2)) {
		data=(void*)luaL_checklstring(L,2,&size);
	} else {
		data=luaL_checklcdata(L,2,&size);
	}
	if (size>state->size) {
		luaL_error(L,"Data size (%l) too large for buffer (%l)",size,state->size);
	}
	cl_int err=clEnqueueWriteBuffer(gpustate->commands,state->buffer,CL_TRUE,0,size,data,0,NULL,NULL);
	if (err!=CL_SUCCESS) {
		luaL_error(L,"%s: Failed to write to buffer",errtostr(err));
	}
	return 0;
}

static int lcl_buffer_index(lua_State* L) {
	lclBuffer* state=*(lclBuffer**)luaL_checkudata(L,1,"opencl.buffer");
	if (lua_isstring(L,2)) {
		const char* func=luaL_checkstring(L,2);
		if (!strcmp(func,"read")) {
			lua_pushcfunction(L,lcl_buffer_read);
			return 1;
		} else if (!strcmp(func,"write")) {
			lua_pushcfunction(L,lcl_buffer_write);
			return 1;
		} else if (!strcmp(func,"typeid")) {
			lua_pushinteger(L,state->ctype);
			return 1;
		}
	}
	lua_pushnil(L);
	return 1;
}

extern int lcl_newBuffer(lua_State* L) {
	lclGpu* gpustate=*(lclGpu**)luaL_checkudata(L,1,"opencl.gpu");
	size_t size;
	void* data=NULL;
	lclBuffer** statePtr=(lclBuffer**)lua_newuserdata(L,sizeof(lclBuffer*));
	lclBuffer* state=(lclBuffer*)calloc(sizeof(lclBuffer),1);
	state->ctype=0;
	if (lua_isnumber(L,2)) {
		size=luaL_checkinteger(L,2);
	} else if (lua_isstring(L,2)) {
		data=(void*)luaL_checklstring(L,2,&size);
	} else {
		data=luaL_checklcdata(L,2,&size);
		state->ctype=luaL_checkctype(L,2);
	}
	*statePtr=state;
	state->gpu=gpustate;
	state->size=size;
	gpustate->refcount++;
	state->refcount++;
	if (luaL_newmetatable(L,"opencl.buffer")) {
		lua_pushstring(L,"__index");
		lua_pushcfunction(L,lcl_buffer_index);
		lua_settable(L,-3);
		lua_pushstring(L,"__gc");
		lua_pushcfunction(L,lcl_buffer_gc);
		lua_settable(L,-3);
	}
	lua_setmetatable(L,-2);
	cl_int err;
	state->buffer=clCreateBuffer(gpustate->context,CL_MEM_READ_WRITE,size,NULL,&err);
	if (!state->buffer) {
		luaL_error(L,"%s: Failed to create buffer",errtostr(err));
	}
	if (data!=NULL) {
		cl_int err=clEnqueueWriteBuffer(gpustate->commands,state->buffer,CL_TRUE,0,size,data,0,NULL,NULL);
		if (err!=CL_SUCCESS) {
			luaL_error(L,"Error %s: Failed to write to buffer",errtostr(err));
		}
	}
	return 1;
}

extern int lcl_exec(lua_State* L) {
	lclCode* codestate=*(lclCode**)luaL_checkudata(L,1,"opencl.code");
	lclGpu* gpustate=codestate->gpu;
	
	for (int narg=2;narg<lua_gettop(L)+1;narg++) {
		cl_int err;
		if (lua_isuserdata(L,narg)) {
			lclBuffer* bufferstate=*(lclBuffer**)luaL_checkudata(L,narg,"opencl.buffer");
			if (!bufferstate->buffer) {
				luaL_error(L,"wat");
			}
			err=clSetKernelArg(codestate->kernel,narg-2,sizeof(bufferstate->buffer),&bufferstate->buffer);
			printf("size buffer: %i\n",(int)sizeof(cl_mem));
		} else {
			size_t size;
			void* data=luaL_checklcdata(L,narg,&size);
			err=clSetKernelArg(codestate->kernel,narg-2,size,data);
			printf("size cdata: %i\n",(int)size);
		}
		if (err!=CL_SUCCESS) {
			luaL_error(L,"%s: Failed to set argument %i",errtostr(err),narg-2);
		}
	}
	
	cl_int err=clEnqueueNDRangeKernel(gpustate->commands,codestate->kernel,codestate->dims,NULL,codestate->globalsizes,codestate->localsizes,0,NULL,NULL);
	if (err!=CL_SUCCESS) {
		luaL_error(L,"%s: Failed to execute kernel! %i %i %i",errtostr(err),(int)codestate->dims,(int)(codestate->globalsizes[0]),(int)(codestate->localsizes[0]));
	}
	clFinish(gpustate->commands);
	return 0;
}

/*extern int exec(lua_State* L) {
	size_t global;					  // global domain size for our calculation
	size_t local;					   // local domain size for our calculation
 
	cl_device_id device_id;			 // compute device id 
	cl_context context;				 // compute context
	cl_command_queue commands;		  // compute command queue
	cl_program program;				 // compute program
	cl_kernel kernel;				   // compute kernel
	
	// Connect to a compute device
	//
	int gpu = 1;
	int err = clGetDeviceIDs(NULL, gpu ? CL_DEVICE_TYPE_GPU : CL_DEVICE_TYPE_CPU, 1, &device_id, NULL);
	if (err != CL_SUCCESS) {
		luaL_error(L,"Error %s: Failed to create a device group!",errtostr(err));
	}
  
	// Create a compute context 
	//
	context = clCreateContext(0, 1, &device_id, NULL, NULL, &err);
	if (!context) {
		luaL_error(L,"Error: Failed to create a compute context!");
	}
 
	// Create a command commands
	//
	commands = clCreateCommandQueue(context, device_id, 0, &err);
	if (!commands) {
		luaL_error(L,"Error: Failed to create a command commands!");
	}
 
	// Create the compute program from the source buffer
	//
	const char* src[1];
	src[0]=luaL_checkstring(L,1);
	program = clCreateProgramWithSource(context, 1, src, NULL, &err);
	if (!program) {
		printf("Error: Failed to create compute program!");
		return EXIT_FAILURE;
	}
 
	// Build the program executable
	//
	err = clBuildProgram(program, 0, NULL, NULL, NULL, NULL);
	if (err != CL_SUCCESS) {
		size_t len;
		char buffer[2048];
		clGetProgramBuildInfo(program, device_id, CL_PROGRAM_BUILD_LOG, sizeof(buffer), buffer, &len);
		luaL_error(L,"Error %s: Failed to build program executable! %s",errtostr(err),buffer);
	}
 
	// Create the compute kernel in the program we wish to run
	//
	kernel = clCreateKernel(program, "square", &err);
	if (!kernel || err != CL_SUCCESS) {
		luaL_error(L,"Error %s: Failed to create compute kernel!",errtostr(err));
		exit(1);
	}
 
	// Create the input and output arrays in device memory for our calculation
	//
	for (int narg=2;narg<lua_gettop(L);narg++) {
		size_t datasize;
		void* data=luaL_checklcdata(L,narg,&datasize);
		clSetKernelArg(kernel,narg-2,datasize,data);
		cl_mem buffer=clCreateBuffer(context,CL_MEM_READ_WRITE,datasize);
		if (!data) {
			luaL_error(L,"Failed to allocate arg %i",narg);
		}
		int err=clEnqueueWriteBuffer(commands,buffer,CL_TRUE,0,datasize,data,0,NULL,NULL);
		if (err!=CL_SUCCESS) {
			luaL_error(L,"Error %s: Failed to write arg %i",errtostr(err),narg);
		}
		int err=clSetKernelArg(kernel,narg-2,sizeof(cl_mem),&buffer);
		if (err!=CL_SUCCESS) {
			luaL_error(L,"Error %s: Failed to set arg %i",errtostr(err),narg);
		}
		
	}
	
	err = clGetKernelWorkGroupInfo(kernel, device_id, CL_KERNEL_WORK_GROUP_SIZE, sizeof(local), &local, NULL);
	if (err != CL_SUCCESS) {
		luaL_error(L,"Error: Failed to retrieve kernel work group info! %s",errtostr(err));
	}
 
	// Execute the kernel over the entire range of our 1d input data set
	// using the maximum number of work group items for this device
	//
	global = count;
	err = clEnqueueNDRangeKernel(commands, kernel, 1, NULL, &global, &local, 0, NULL, NULL);
	if (err) {
		luaL_error(L,"Error %s: Failed to execute kernel!",errtostr(err));
	}
 
	// Wait for the command commands to get serviced before reading back results
	//
	clFinish(commands);
 
	// Read back the results from the device to verify the output
	//
	err = clEnqueueReadBuffer( commands, output, CL_TRUE, 0, sizeof(float) * count, results, 0, NULL, NULL );  
	if (err != CL_SUCCESS) {
		luaL_error(L,"Error: Failed to read output array! %d", err);
		exit(1);
	}
	
	// Shutdown and cleanup
	//
	clReleaseMemObject(input);
	clReleaseMemObject(output);
	clReleaseProgram(program);
	clReleaseKernel(kernel);
	clReleaseCommandQueue(commands);
	clReleaseContext(context);
	
	return 0;
}
*/

