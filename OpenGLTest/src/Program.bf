using System;
namespace OpenGLTest;

using OpenGL;
using SDL2;

class Program
{
	const String vertexShaderSource = @"""
#version 300 es
precision highp float;
layout (location = 0) in vec4 Position0;
layout (location = 1) in vec4 Color0;
out vec4 color;
void main()
{    
    gl_Position = Position0;	
    color = Color0;
}
""";

	const String fragmentShaderSource = @"""
#version 300 es
precision highp float;
in vec4 color;
out vec4 fragColor;
void main() 
{    	 	 	
    fragColor = color;	 	
}
""";

	public static void Main(String[] args)
	{
		SDL.GL_SetAttribute(SDL.SDL_GLAttr.GL_CONTEXT_MAJOR_VERSION, 4);
		SDL.GL_SetAttribute(SDL.SDL_GLAttr.GL_CONTEXT_MINOR_VERSION, 0);

		SDL.Window* window = SDL.CreateWindow(
			"OpenGL.NET Test",
			.Centered,
			.Centered,
			960,
			540,
			.OpenGL | .Shown);

		SDL.SDL_GLContext context = SDL.GL_CreateContext(window);
		SDL.SDL_GL_MakeCurrent(window, context);

		function void*(StringView) glGetProcAddress = (proc) =>
			{
				return SDL.SDL_GL_GetProcAddress(proc.Ptr);
			};

		GL.LoadGetString( => glGetProcAddress);

		Console.WriteLine("OpenGL Version: {0}", scope String((char8*)GL.glGetString(StringName.Version)));

		// Now load the rest of the functions in one go
		GL.LoadAllFunctions( => glGetProcAddress);

		uint32 vertexShader = GL.glCreateShader(ShaderType.VertexShader);

		void*[] textPtr = scope void*[1];
		var lengthArray = scope int32[1];

		lengthArray[0] = (.)vertexShaderSource.Length;
		textPtr[0] = vertexShaderSource.Ptr;

		GL.glShaderSource(vertexShader, 1, textPtr.Ptr, lengthArray.Ptr);
		GL.glCompileShader(vertexShader);

		// checkErrors
		int32 success = 0;
		var infoLog = scope char8[512];
		lengthArray[0] = success;
		GL.glGetShaderiv(vertexShader, ShaderParameterName.CompileStatus, lengthArray.Ptr);
		if (success > 0)
		{
			GL.glGetShaderInfoLog(vertexShader, 512, (int32*)null, infoLog.Ptr);
			Console.WriteLine($"Error: vertex shader compilation failed: {scope String(&infoLog[0])}");
		}

		uint32 fragmentShader = GL.glCreateShader(ShaderType.FragmentShader);

		lengthArray[0] = (.)fragmentShaderSource.Length;
		textPtr[0] = fragmentShaderSource.Ptr;
		GL.glShaderSource(fragmentShader, 1, textPtr.Ptr, lengthArray.Ptr);
		GL.glCompileShader(fragmentShader);

		// checkErrors
		lengthArray[0] = success;
		GL.glGetShaderiv(fragmentShader, ShaderParameterName.CompileStatus, lengthArray.Ptr);
		if (success > 0)
		{
			GL.glGetShaderInfoLog(fragmentShader, 512, (int32*)null, infoLog.Ptr);
			Console.WriteLine($"Error: shader fragment compilation failed: {scope String(&infoLog[0])}");
		}

		uint32 shaderProgram = GL.glCreateProgram();
		GL.glAttachShader(shaderProgram, vertexShader);
		GL.glAttachShader(shaderProgram, fragmentShader);
		GL.glLinkProgram(shaderProgram);

		// checkErrors
		lengthArray[0] = success;
		GL.glGetProgramiv(shaderProgram, ProgramPropertyARB.LinkStatus, lengthArray.Ptr);
		if (success > 0)
		{
			GL.glGetProgramInfoLog(shaderProgram, 512, (int32*)null, infoLog.Ptr);
			Console.WriteLine($"Error: shader program compilation failed: {scope String(&infoLog[0])}");
		}

		GL.glDeleteShader(vertexShader);
		GL.glDeleteShader(fragmentShader);

		float[] vertices = scope .(
			0f, 0.5f, 0.0f, 1.0f, 1.0f, 0.0f, 0.0f, 1.0f,
			0.5f, -0.5f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f, 1.0f,
			-0.5f, -0.5f, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 1.0f
			);

		uint32 VBO = 0;
		uint32 VAO = 0;
		GL.glGenVertexArrays(1, &VAO);
		GL.glGenBuffers(1, &VBO);

		GL.glBindVertexArray(VAO);
		GL.glBindBuffer(BufferTargetARB.ArrayBuffer, VBO);

		float* verticesPtr = vertices.Ptr;
		{
			GL.glBufferData(BufferTargetARB.ArrayBuffer, (.)(vertices.Count * sizeof(float)), verticesPtr, BufferUsageARB.StaticDraw);
		}

		int32 stride = 8 * sizeof(float);
		GL.glVertexAttribPointer(0, 4, VertexAttribPointerType.Float, false, stride, (void*)null);
		GL.glEnableVertexAttribArray(0);

		GL.glVertexAttribPointer(1, 4, VertexAttribPointerType.Float, false, stride, (void*)16);
		GL.glEnableVertexAttribArray(1);

		GL.glBindBuffer(BufferTargetARB.ArrayBuffer, 0);

		GL.glBindVertexArray(0);

		bool running = true;
		while (running)
		{
			SDL.Event evt;
			while (SDL.PollEvent(out evt) != 0)
			{
				if (evt.type == SDL.EventType.Quit)
				{
					running = false;
				}
			}

			GL.glClearColor(0f, 0f, 0f, 1f);
			GL.glClear((uint)AttribMask.ColorBufferBit);

			GL.glUseProgram(shaderProgram);
			GL.glBindVertexArray(VAO);
			GL.glDrawArrays(PrimitiveType.Triangles, 0, 3);

			SDL.GL_SwapWindow(window);
		}

		GL.glDeleteVertexArrays(1, &VAO);
		GL.glDeleteBuffers(1, &VBO);

		SDL.DestroyWindow(window);
	}
}
