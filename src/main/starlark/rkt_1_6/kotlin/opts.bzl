def _map_optin_class_to_flag(values):
    return ["-opt-in=%s" % v for v in values]

def _map_backend_threads_to_flag(n):
    if n == 1:
        return None
    return ["-Xbackend-threads=%d" % n]

_KOPTS = {
    "warn": struct(
        args = dict(
            default = "report",
            doc = "Control warning behaviour.",
            values = ["off", "report", "error"],
        ),
        type = attr.string,
        value_to_flag = {
            "off": ["-nowarn"],
            "report": None,
            "error": ["-Werror"],
        },
    ),
    "include_stdlibs": struct(
        args = dict(
            default = "all",
            doc = "Don't automatically include the Kotlin standard libraries into the classpath (stdlib and reflect).",
            values = ["all", "stdlib", "none"],
        ),
        type = attr.string,
        value_to_flag = {
            "all": None,
            "stdlib": ["-no-reflect"],
            "none": ["-no-stdlib"],
        },
    ),
    "x_skip_prerelease_check": struct(
        args = dict(
            default = False,
            doc = "Suppress errors thrown when using pre-release classes.",
        ),
        type = attr.bool,
        value_to_flag = {
            True: ["-Xskip-prerelease-check"],
        },
    ),
    "x_inline_classes": struct(
        args = dict(
            default = False,
            doc = "Enable experimental inline classes",
        ),
        type = attr.bool,
        value_to_flag = {
            True: ["-Xinline-classes"],
        },
    ),
    "x_allow_result_return_type": struct(
        args = dict(
            default = False,
            doc = "Enable kotlin.Result as a return type",
        ),
        type = attr.bool,
        value_to_flag = {
            True: ["-Xallow-result-return-type"],
        },
    ),
    "x_jvm_default": struct(
        args = dict(
            default = "off",
            doc = "Specifies that a JVM default method should be generated for non-abstract Kotlin interface member.",
            values = ["off", "enable", "disable", "compatibility", "all-compatibility", "all"],
        ),
        type = attr.string,
        value_to_flag = {
            "off": None,
            "enable": ["-Xjvm-default=enable"],
            "disable": ["-Xjvm-default=disable"],
            "compatibility": ["-Xjvm-default=compatibility"],
            "all-compatibility": ["-Xjvm-default=all-compatibility"],
            "all": ["-Xjvm-default=all"],
        },
    ),
    "x_no_optimized_callable_references": struct(
        args = dict(
            default = False,
            doc = "Do not use optimized callable reference superclasses. Available from 1.4.",
        ),
        type = attr.bool,
        value_to_flag = {
            True: ["-Xno-optimized-callable-reference"],
        },
    ),
    "x_explicit_api_mode": struct(
        args = dict(
            default = "off",
            doc = "Enable explicit API mode for Kotlin libraries.",
            values = ["off", "warning", "strict"],
        ),
        type = attr.string,
        value_to_flag = {
            "off": None,
            "warning": ["-Xexplicit-api=warning"],
            "strict": ["-Xexplicit-api=strict"],
        },
    ),
    "java_parameters": struct(
        args = dict(
            default = False,
            doc = "Generate metadata for Java 1.8+ reflection on method parameters.",
        ),
        type = attr.bool,
        value_to_flag = {
            True: ["-java-parameters"],
        },
    ),
    "x_multi_platform": struct(
        args = dict(
            default = False,
            doc = "Enable experimental language support for multi-platform projects",
        ),
        type = attr.bool,
        value_to_flag = {
            True: ["-Xmulti-platform"],
        },
    ),
    "x_emit_jvm_type_annotations": struct(
        args = dict(
            default = False,
            doc = "Basic support for type annotations in JVM bytecode.",
        ),
        type = attr.bool,
        value_to_flag = {
            True: ["-Xemit-jvm-type-annotations"],
        },
    ),
    "x_sam_conversions": struct(
        args = dict(
            default = "class",
            doc = "Change codegen behavior of SAM/functional interfaces",
            values = ["class", "indy"],
        ),
        type = attr.string,
        value_to_flag = {
            "class": ["-Xsam-conversions=class"],
            "indy": ["-Xsam-conversions=indy"],
        },
    ),
    "x_lambdas": struct(
        args = dict(
            default = "class",
            doc = "Change codegen behavior of lambdas",
            values = ["class", "indy"],
        ),
        type = attr.string,
        value_to_flag = {
            "class": ["-Xlambdas=class"],
            "indy": ["-Xlambdas=indy"],
        },
    ),
    "x_optin": struct(
        args = dict(
            default = [],
            doc = "Define APIs to opt-in to.",
        ),
        type = attr.string_list,
        value_to_flag = None,
        map_value_to_flag = _map_optin_class_to_flag,
    ),
    "x_use_fir": struct(
        args = dict(
            default = False,
            doc = "Compile using the experimental Kotlin Front-end IR. Available from 1.6.",
        ),
        type = attr.bool,
        value_to_flag = {
            True: ["-Xuse-fir"],
        },
    ),
    "x_no_optimize": struct(
        args = dict(
            default = False,
            doc = "Disable optimizations",
        ),
        type = attr.bool,
        value_to_flag = {
            True: ["-Xno-optimize"],
        },
    ),
    "x_backend_threads": struct(
        args = dict(
            default = 1,
            doc = "When using the IR backend, run lowerings by file in N parallel threads. 0 means use a thread per processor core. Default value is 1.",
        ),
        type = attr.int,
        value_to_flag = None,
        map_value_to_flag = _map_backend_threads_to_flag,
    ),
    "x_report_perf": struct(
        args = dict(
            default = False,
            doc = "Report detailed performance statistics",
        ),
        type = attr.bool,
        value_to_flag = {
            True: ["-Xreport-perf"],
        },
    ),
}

KotlincOptions = provider(
    fields = {
        name: o.args["doc"]
        for name, o in _KOPTS.items()
    },
)

def _kotlinc_options_impl(ctx):
    return struct(
        providers = [
            KotlincOptions(**{n: getattr(ctx.attr, n, None) for n in _KOPTS}),
        ],
    )

kt_kotlinc_options = rule(
    implementation = _kotlinc_options_impl,
    doc = "Define kotlin compiler options.",
    provides = [KotlincOptions],
    attrs = {
        n: o.type(**o.args)
        for n, o in _KOPTS.items()
    },
)

def kotlinc_options_to_flags(kotlinc_options):
    """Translate KotlincOptions to worker flags

    Args:
        kotlinc_options maybe containing KotlincOptions
    Returns:
        list of flags to add to the command line.
    """
    if not kotlinc_options:
        return ""

    flags = []
    for n, o in _KOPTS.items():
        value = getattr(kotlinc_options, n, None)
        flag = o.value_to_flag.get(value, None) if o.value_to_flag else o.map_value_to_flag(value)
        if flag:
            flags.extend(flag)
    return flags
