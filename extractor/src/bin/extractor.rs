use codeql_extractor::{diagnostics, extractor, node_types, trap};

extern crate num_cpus;

use rayon::prelude::*;
use std::fs;
use std::io::BufRead;
use std::path::{Path, PathBuf};

fn main() -> std::io::Result<()> {
    tracing_subscriber::fmt()
        .with_target(false)
        .without_time()
        .with_level(true)
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    let diagnostics = diagnostics::DiagnosticLoggers::new("language");
    let mut main_thread_logger = diagnostics.logger();
    let num_threads = match codeql_extractor::options::num_threads() {
        Ok(num) => num,
        Err(e) => {
            main_thread_logger.write(
                main_thread_logger
                    .new_entry("configuration-error", "Configuration error")
                    .message(
                        "{}; defaulting to 1 thread.",
                        &[diagnostics::MessageArg::Code(&e)],
                    )
                    .severity(diagnostics::Severity::Warning),
            );
            1
        }
    };
    tracing::info!(
        "Using {} {}",
        num_threads,
        if num_threads == 1 {
            "thread"
        } else {
            "threads"
        }
    );

    let trap_compression = match trap::Compression::from_env("CODEQL_LANGUAGE_TRAP_COMPRESSION")
    {
        Ok(x) => x,
        Err(e) => {
            main_thread_logger.write(
                main_thread_logger
                    .new_entry("configuration-error", "Configuration error")
                    .message("{}; using gzip.", &[diagnostics::MessageArg::Code(&e)])
                    .severity(diagnostics::Severity::Warning),
            );
            trap::Compression::Gzip
        }
    };
    drop(main_thread_logger);

    rayon::ThreadPoolBuilder::new()
        .num_threads(num_threads)
        .build_global()
        .unwrap();

    let matches = clap::App::new("Language extractor")
        .version("1.0")
        .author("GitHub")
        .about("CodeQL Language extractor")
        .args_from_usage(
            "--source-archive-dir=<DIR> 'Sets a custom source archive folder'
                    --output-dir=<DIR>         'Sets a custom trap folder'
                    --file-list=<FILE_LIST>    'A text files containing the paths of the files to extract'",
        )
        .get_matches();
    let src_archive_dir = matches
        .value_of("source-archive-dir")
        .expect("missing --source-archive-dir");
    let src_archive_dir = PathBuf::from(src_archive_dir);

    let trap_dir = matches
        .value_of("output-dir")
        .expect("missing --output-dir");
    let trap_dir = PathBuf::from(trap_dir);

    let file_list = matches.value_of("file-list").expect("missing --file-list");
    let file_list = fs::File::open(file_list)?;

    let language = tree_sitter_language::language();
    let schema =
        node_types::read_node_types_str("language", tree_sitter_language::NODE_TYPES)?;

    let lines: std::io::Result<Vec<String>> = std::io::BufReader::new(file_list).lines().collect();
    let lines = lines?;
    lines
        .par_iter()
        .try_for_each(|line| {
            let path = PathBuf::from(line).canonicalize()?;
            let src_archive_file = path_for(&src_archive_dir, &path, "");
            let source = std::fs::read(&path)?;
            let code_ranges = vec![];
            let mut diagnostics_writer = diagnostics.logger();
            let mut trap_writer = trap::Writer::new();

            extractor::extract(
                language,
                "language",
                &schema,
                &mut diagnostics_writer,
                &mut trap_writer,
                &path,
                &source,
                &code_ranges,
            );

            std::fs::create_dir_all(&src_archive_file.parent().unwrap())?;
            std::fs::copy(&path, &src_archive_file)?;
            write_trap(&trap_dir, path, &trap_writer, trap_compression)
        })
        .expect("failed to extract files");

    let path = PathBuf::from("extras");
    let mut trap_writer = trap::Writer::new();
    extractor::populate_empty_location(&mut trap_writer);
    write_trap(&trap_dir, path, &trap_writer, trap_compression)
}

fn write_trap(
    trap_dir: &Path,
    path: PathBuf,
    trap_writer: &trap::Writer,
    trap_compression: trap::Compression,
) -> std::io::Result<()> {
    let trap_file = path_for(trap_dir, &path, trap_compression.extension());
    std::fs::create_dir_all(&trap_file.parent().unwrap())?;
    trap_writer.write_to_file(&trap_file, trap_compression)
}

fn path_for(dir: &Path, path: &Path, ext: &str) -> PathBuf {
    let mut result = PathBuf::from(dir);
    for component in path.components() {
        match component {
            std::path::Component::Prefix(prefix) => match prefix.kind() {
                std::path::Prefix::Disk(letter) | std::path::Prefix::VerbatimDisk(letter) => {
                    result.push(format!("{}_", letter as char))
                }
                std::path::Prefix::Verbatim(x) | std::path::Prefix::DeviceNS(x) => {
                    result.push(x);
                }
                std::path::Prefix::UNC(server, share)
                | std::path::Prefix::VerbatimUNC(server, share) => {
                    result.push("unc");
                    result.push(server);
                    result.push(share);
                }
            },
            std::path::Component::RootDir => {
                // skip
            }
            std::path::Component::Normal(_) => {
                result.push(component);
            }
            std::path::Component::CurDir => {
                // skip
            }
            std::path::Component::ParentDir => {
                result.pop();
            }
        }
    }
    if !ext.is_empty() {
        match result.extension() {
            Some(x) => {
                let mut new_ext = x.to_os_string();
                new_ext.push(".");
                new_ext.push(ext);
                result.set_extension(new_ext);
            }
            None => {
                result.set_extension(ext);
            }
        }
    }
    result
}
