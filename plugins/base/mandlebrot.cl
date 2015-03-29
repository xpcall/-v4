#ifdef cl_khr_fp64
    #pragma OPENCL EXTENSION cl_khr_fp64 : enable
#elif defined(cl_amd_fp64)
    #pragma OPENCL EXTENSION cl_amd_fp64 : enable
#else
    #error "Double precision floating point not supported by OpenCL implementation."
#endif

char smooth(char a,char b,float n) {
	return a+((b-a)*n);
} 

__kernel void main(__global unsigned char data[1000][1000][3],__global unsigned char pallete[256][3]) {
	float x0=-2;
	float y0=-1;
	float x1=0.5;
	float y1=1;
	float dx=x1-x0;
	float dy=y1-y0;
	//int x=get_global_id(0)%1000;
	//int y=get_global_id(0)/1000;
	//for (int x=0;x<1000;x++) {
	int tx=get_global_id(0);
	for (int x=tx*4;x<(tx*4)+4&&x<1000;x++) {
		for (int y=0;y<1000;y++) {
			float r=0;
			float n=0;
			float b=(x/1000.0)*dx+x0;
			float e=(y/1000.0)*dy+y0;
			float i=0;
			while ( b*b + e*e < (1<<16)&&i<256) {
				float xtemp=b*b-e*e+x0;
				e=2*b*e+y0;
				b=xtemp;
				i++;
			}
			i+=1-(log(log(sqrt((float)(r*r+n*n)))/log((float)2))/log((float)2));
			int c1=(int)i%256;
			int c2=min((int)i+1,255);
			data[x][y][0]=smooth(pallete[c1][0],pallete[c2][0],(i,1));
			data[x][y][1]=smooth(pallete[c1][1],pallete[c2][1],fmod(i,1));
			data[x][y][2]=smooth(pallete[c1][2],pallete[c2][2],fmod(i,1));
		}
	}
}