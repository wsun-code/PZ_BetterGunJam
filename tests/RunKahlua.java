import java.io.PrintStream;
import java.io.Reader;
import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.nio.file.Files;
import java.nio.file.Path;

/** Executes Lua files in one Project Zomboid Kahlua environment. */
public final class RunKahlua {
    private RunKahlua() {
    }

    public static void main(String[] args) throws Exception {
        Class<?> platformType = Class.forName("se.krka.kahlua.j2se.J2SEPlatform");
        Class<?> platformInterface = Class.forName("se.krka.kahlua.vm.Platform");
        Class<?> tableType = Class.forName("se.krka.kahlua.vm.KahluaTable");
        Class<?> compilerType = Class.forName("se.krka.kahlua.luaj.compiler.LuaCompiler");
        Class<?> threadType = Class.forName("se.krka.kahlua.vm.KahluaThread");

        Object platform = platformType.getMethod("getInstance").invoke(null);
        Object environment = platformType.getMethod("newEnvironment").invoke(platform);
        compilerType.getMethod("register", tableType).invoke(null, environment);

        Constructor<?> threadConstructor = threadType.getConstructor(
            PrintStream.class,
            platformInterface,
            tableType
        );
        Object thread = threadConstructor.newInstance(System.out, platform, environment);
        threadType.getField("debugOwnerThread").set(thread, Thread.currentThread());

        Method load = compilerType.getMethod("loadis", Reader.class, String.class, tableType);
        Method call = threadType.getMethod("call", Object.class, Object[].class);

        for (String argument : args) {
            runLuaFile(Path.of(argument), environment, thread, load, call);
        }
    }

    private static void runLuaFile(
        Path path,
        Object environment,
        Object thread,
        Method load,
        Method call
    ) throws Exception {
        try (Reader reader = Files.newBufferedReader(path)) {
            Object closure = load.invoke(null, reader, path.toString(), environment);
            call.invoke(thread, closure, new Object[0]);
        } catch (InvocationTargetException exception) {
            Throwable cause = exception.getCause();
            if (cause instanceof Exception nestedException) {
                throw nestedException;
            }
            if (cause instanceof Error error) {
                throw error;
            }
            throw exception;
        }
    }
}
