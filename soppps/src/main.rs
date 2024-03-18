use std::{
    fs::{read_to_string, File, OpenOptions},
    io::{BufRead, BufReader, BufWriter, Seek, Write},
    path::PathBuf,
};

use anyhow::{Context, Result};
use clap::Parser;
use glob::glob;

fn collect_files(path: PathBuf) -> Result<Vec<PathBuf>> {
    let cfg = File::open(path)?;
    let cfg = BufReader::new(cfg);
    let paths = cfg.lines();
    let mut res: Vec<PathBuf> = Vec::new();
    for p in paths {
        let globbed = glob(&p?)?;
        let files = globbed.flatten().filter(|p| p.is_file());
        res.extend(files);
    }
    Ok(res)
}

fn parse_path(secret: &str) -> PathBuf {
    let mut p = String::new();
    for c in secret.chars() {
        if c.is_whitespace() || c.is_control() || c == '"' || c == '\'' {
            break;
        }
        p.push(c);
    }
    p.into()
}

fn process_file(path: PathBuf) -> Result<()> {
    let mut file = BufReader::new(File::open(&path)?);
    let mut line = String::new();
    let mut new_content: Vec<String> = Vec::new();
    let mut start_index: u64 = 0;
    loop {
        line.clear();
        if file.read_line(&mut line)? == 0 {
            break;
        }
        let pattern = "secret:";
        let index = line.find(pattern);
        if let Some(index) = index {
            if start_index == 0 {
                //start of file buffer that needs to be rewritten
                start_index = file.stream_position()? - line.len() as u64;
            }
            let (start, secret) = line.split_at(index);
            let (_, secret) = secret.split_at(pattern.len());
            let sec_path = parse_path(secret);
            let (_, rem) = secret.split_at(sec_path.to_str().unwrap_or_default().len());
            let secret = read_to_string(sec_path).context("Secret File")?;
            let l = start.to_string() + &secret + rem;
            new_content.push(l);
        } else if !new_content.is_empty() {
            new_content.push(line.clone());
        }
    }
    let opts = OpenOptions::new().write(true).open(path)?;
    let mut writer = BufWriter::new(&opts);
    let _ = writer.seek(std::io::SeekFrom::Start(start_index))?;
    for l in new_content {
        let _ = writer.write(l.as_bytes())?;
    }
    opts.set_len(writer.stream_position()?)?;
    writer.flush()?;
    Ok(())
}

#[derive(Parser, Debug)]
#[command(version)]
struct Args {
    config_file: String,
}

fn main() -> Result<()> {
    let args = Args::parse();
    let files = collect_files(PathBuf::from(args.config_file))?;
    for f in files {
        process_file(f)?;
    }
    Ok(())
}
