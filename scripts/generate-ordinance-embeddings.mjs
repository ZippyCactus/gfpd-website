import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const WORKER_URL = process.env.WORKER_URL || 'https://gfpd-ai-proxy.mc-bygone.workers.dev';
const ORDINANCES_PATH = path.resolve(__dirname, '../assets/data/ordinances.json');
const OUTPUT_PATH = path.resolve(__dirname, '../assets/data/ordinances-embeddings.json');

const MAX_CHARS_PER_CHUNK = 1800;
const SENTENCE_SPLIT_REGEX = /(?<=[.!?])\s+/;
const BATCH_SIZE = 16;

function chunkText(text, maxChars = MAX_CHARS_PER_CHUNK) {
    if (!text) return [];
    const sentences = text.split(SENTENCE_SPLIT_REGEX);
    const chunks = [];
    let current = '';

    sentences.forEach((sentence) => {
        const trimmed = sentence.trim();
        if (!trimmed) return;

        if ((current + ' ' + trimmed).trim().length <= maxChars) {
            current = (current ? current + ' ' : '') + trimmed;
        } else {
            if (current) {
                chunks.push(current.trim());
            }
            if (trimmed.length > maxChars) {
                for (let i = 0; i < trimmed.length; i += maxChars) {
                    const slice = trimmed.slice(i, i + maxChars);
                    chunks.push(slice.trim());
                }
                current = '';
            } else {
                current = trimmed;
            }
        }
    });

    if (current) {
        chunks.push(current.trim());
    }

    return chunks;
}

async function main() {
    console.log('Loading ordinances from', ORDINANCES_PATH);
    const raw = await fs.readFile(ORDINANCES_PATH, 'utf-8');
    const ordinances = JSON.parse(raw);

    const chunkedEntries = [];
    ordinances.forEach((ordinance) => {
        const { id, title, url, hierarchy, text } = ordinance;
        const chunks = chunkText(text);
        if (chunks.length === 0) return;
        chunks.forEach((chunkTextValue, index) => {
            chunkedEntries.push({
                id: `${id}__chunk_${index + 1}`,
                ordinanceId: id,
                title,
                url,
                hierarchy,
                text: chunkTextValue,
            });
        });
    });

    console.log(`Prepared ${chunkedEntries.length} chunks. Requesting embeddings from worker at ${WORKER_URL}`);

    const embeddings = [];
    for (let i = 0; i < chunkedEntries.length; i += BATCH_SIZE) {
        const batch = chunkedEntries.slice(i, i + BATCH_SIZE);
        const payload = {
            type: 'embedding',
            texts: batch.map((entry) => entry.text),
        };

        let response;
        try {
            response = await fetch(WORKER_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload),
            });
        } catch (error) {
            console.error('Network error when calling worker:', error);
            process.exit(1);
        }

        if (!response.ok) {
            const errorText = await response.text();
            console.error(`Worker responded with ${response.status}: ${errorText}`);
            process.exit(1);
        }

        const data = await response.json();
        const batchEmbeddings = data.embeddings || data.responses;
        if (!Array.isArray(batchEmbeddings)) {
            console.error('Unexpected embedding response shape:', data);
            process.exit(1);
        }

        batchEmbeddings.forEach((embeddingItem, offset) => {
            const values = embeddingItem.values || embeddingItem.embedding || embeddingItem;
            if (!Array.isArray(values)) {
                console.error('Missing embedding values for item', embeddingItem);
                process.exit(1);
            }
            const source = batch[offset];
            embeddings.push({
                id: source.id,
                ordinanceId: source.ordinanceId,
                title: source.title,
                url: source.url,
                hierarchy: source.hierarchy,
                text: source.text,
                embedding: values,
            });
        });

        process.stdout.write(`Embedded ${Math.min(i + BATCH_SIZE, chunkedEntries.length)} / ${chunkedEntries.length}\r`);
    }

    console.log(`\nWriting embeddings to ${OUTPUT_PATH}`);
    await fs.writeFile(OUTPUT_PATH, JSON.stringify({ generatedAt: new Date().toISOString(), embeddings }, null, 2), 'utf-8');
    console.log('Done.');
}

main().catch((error) => {
    console.error('Failed to generate embeddings:', error);
    process.exit(1);
});


