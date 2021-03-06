module lib.graphics.wackyRender;

import std.stdio;
import std.string;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import derelict.util.exception:
DerelictException;

public import wackyEnums;
public import wackyExceptions;
import lib.graphics.wackyShaderProgram;
import lib.graphics.wackyPipeline;
import lib.graphics.wackyCamera;

class WackyRender
{
public:

    WackyShaderProgram shaderProgram;
    WackyPipeline pipeline;

    this(int width, int height, string name, WackyWindowMode mode)
    {
        if (!DerelictGLFW3.isLoaded)
        {
            try
            {
                DerelictGLFW3.load;
            }
            catch (DerelictException)
            {
                throw new WackyException("GLFW3 or one of its dependencies "
                                         "cannot be found on the file system");
            }
        }

        if (!DerelictGL3.isLoaded)
        {
            try
            {
                DerelictGL3.load;
            }
            catch (DerelictException)
            {
                throw new WackyException("OpenGL3 or one of its dependencies "
                                         "cannot be found on the file system");
            }
        }

        this.width = width;
        this.height = height;
        this.name = name;
        this.mode = mode;

        initialize(this.width, this.height, this.name, this.mode);

        shaderProgram = new WackyShaderProgram();
        pipeline = new WackyPipeline();
    }

    ~this()
    {
        glfwDestroyWindow(window);
        glfwTerminate();
        DerelictGL3.unload();
        DerelictGLFW3.unload();
    }


    /**
    *   Main loop.
    *   The parameter action() should contain all the objects to be rendered
    */

    auto execute(alias action)()
    {
        float mainTime = glfwGetTime();
        while(!glfwWindowShouldClose(window))
        {
            if (isNextFrame(mainTime))
            {
                glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
                glfwPollEvents();

                action();

                glfwSwapBuffers(window);
            }
        }
    }

    /**
     *  Returns the number of seconds since the constructor
     *  for WackyRender was called
     */
    auto getTime() nothrow
    {
        return glfwGetTime();
    }

    /**
     * Sets a key and an action for making the window close
     */
    auto setExitKeyAndAction(WackyKeys key, WackyActions action) nothrow
    {
        exitKey = key;
        exitAction = action;
    }

    /**
     *  Setting MINIMAL time per frame.
     *  It may happen that the time segment is
     *  too short for a frame to be rendered,
     *  so the segment is only a lower limit
     *  for a frame rendering time
     */
    auto setMinimalTimePerFrame(float seconds) pure nothrow
    {
        timePerFrame = seconds;
    }

    /**
     * Getters
     */
    @property
    {
        auto SPF() pure nothrow
        {
            return timePerFrame;
        }

        auto FPS() pure nothrow
        {
            return 1.0f / timePerFrame;
        }

        auto windowPointer() pure nothrow
        {
            return window;
        }

        auto windowWidth() pure nothrow
        {
            return width;
        }

        auto windowHeight() pure nothrow
        {
            return width;
        }

        auto windowName() pure nothrow
        {
            return name;
        }

        auto windowMode() pure nothrow
        {
            return mode;
        }

        auto currentExitKey() nothrow
        {
            return exitKey;
        }

        auto currentExitAction() nothrow
        {
            return exitAction;
        }
    }

private:

    int width;
    int height;
    string name;
    WackyWindowMode mode;

    GLFWwindow* window;

    static WackyKeys exitKey = WackyKeys.KEY_ESCAPE;
    static WackyActions exitAction = WackyActions.PRESS;

    float timePerFrame = 0.001f; // 0.001 second
    /**
     *  The function does all necessary work for the render functioning
     */
    auto initialize (int width, int height, string name, WackyWindowMode mode)
    {
        if (glfwInit() == GL_FALSE)
            throw new WackyRenderException("Error while initializing GLFW3");

        if (isBadResolution(width, height))
            throw new WackyRenderException("Invalid resolution");

        GLFWmonitor* monitor;
        if (mode == WackyWindowMode.FULLSCREEN_MODE)
            monitor = glfwGetPrimaryMonitor();

        window = glfwCreateWindow (width, height, name.ptr, monitor, null);
        if (!window)
            throw new WackyRenderException("Error while creating window");

        setCallbacks();
        glfwSetInputMode (window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);

        glfwMakeContextCurrent (window);
        glfwSetCursorPos(window, 0.0f, 0.0f);
        DerelictGL3.reload();
    }

    /**
     *  Resolution validation
     */
    auto static isBadResolution(int width, int height)
    {
        const GLFWvidmode* maxResolution = glfwGetVideoMode(glfwGetPrimaryMonitor());

        return width < 100
               || height < 100
               || width > maxResolution.width
               || height > maxResolution.height;
    }

    /**
     *  Sets the callbacks
     */
    auto setCallbacks()
    {
        glfwSetMouseButtonCallback (window, cast(GLFWmousebuttonfun ) &mouseButtonCallback);
        glfwSetKeyCallback (window, cast(GLFWkeyfun) &keyboardCallback);
        glfwSetCursorPosCallback (window, cast(GLFWcursorposfun) &mouseMoveCallback);
    }

    /**
     *   GLFW3 callbacks
     */

    /**
     *  FPS handler
     */
    auto isNextFrame(ref float previous)
    {
        auto current = glfwGetTime();
        if (current - previous > timePerFrame)
        {
            previous = current;
            return true;
        }
        return false;
    }

    // There will be some changes
    extern(C) static auto mouseButtonCallback (GLFWwindow* window, int key, int action, int mods) nothrow
    {
    }

    extern(C) static auto mouseMoveCallback (GLFWwindow* window, double x, double y) nothrow
    {
    }

    extern(C) static auto keyboardCallback (GLFWwindow* window, int key, int scancode, int action, int mods) nothrow
    {
        if (key == exitKey && action == exitAction)
            glfwSetWindowShouldClose (window, true);
    }
}
