const ExcelJS = require("exceljs");
const fs = require("fs");

async function generate(dataJsonPath, outputPath) { // Removed logoPath parameter
    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'HR System';
    workbook.lastModifiedBy = 'HR System';
    workbook.created = new Date();
    workbook.modified = new Date();

    const sheet = workbook.addWorksheet("Training Report", {
        pageSetup: { 
            paperSize: 9, // A4
            orientation: 'landscape',
            margins: { left: 0.7, right: 0.7, top: 0.75, bottom: 0.75, header: 0.3, footer: 0.3 }
        }
    });

    const data = JSON.parse(fs.readFileSync(dataJsonPath));
    if (!Array.isArray(data) || data.length === 0) {
        throw new Error("No data provided.");
    }

    const headers = Object.keys(data[0]);
    const lastColLetter = String.fromCharCode(64 + headers.length);

    // === Style Definitions ===
    const styles = {
        title: {
            font: { bold: true, size: 14, name: 'Calibri' },
            alignment: { horizontal: "center", vertical: "middle" }
        },
        subtitle: {
            font: { bold: true, size: 12, name: 'Calibri' },
            alignment: { horizontal: "center", vertical: "middle" }
        },
        date: {
            font: { italic: true, size: 10, name: 'Calibri' },
            alignment: { horizontal: "right", vertical: "middle" }
        },
        header: {
            font: { bold: true, size: 11, name: 'Calibri', color: { argb: 'FFFFFFFF' } },
            alignment: { horizontal: "center", vertical: "middle" },
            fill: {
                type: 'pattern',
                pattern: 'solid',
                fgColor: { argb: 'FF4472C4' }
            },
            border: {
                top: { style: 'thin', color: { argb: 'FF000000' } },
                bottom: { style: 'thin', color: { argb: 'FF000000' } },
                left: { style: 'thin', color: { argb: 'FF000000' } },
                right: { style: 'thin', color: { argb: 'FF000000' } }
            }
        },
        dataRow: {
            font: { size: 11, name: 'Calibri' },
            alignment: { vertical: "middle" },
            border: {
                bottom: { style: 'thin', color: { argb: 'FFD9D9D9' } },
                left: { style: 'thin', color: { argb: 'FFD9D9D9' } },
                right: { style: 'thin', color: { argb: 'FFD9D9D9' } }
            }
        }
    };

    // === Title Section ===
    // Merge all columns for title rows
    sheet.mergeCells(`A1:${lastColLetter}1`);
    const titleCell = sheet.getCell("A1");
    titleCell.value = "HUMAN RESOURCE MANAGEMENT DEPARTMENT";
    Object.assign(titleCell, styles.title);

    sheet.mergeCells(`A2:${lastColLetter}2`);
    const subTitleCell = sheet.getCell("A2");
    subTitleCell.value = "TRAINING APPLICATIONS REGISTER";
    Object.assign(subTitleCell, styles.subtitle);

    sheet.mergeCells(`A3:${lastColLetter}3`);
    const dateCell = sheet.getCell("A3");
    dateCell.value = `Exported on: ${new Date().toLocaleDateString('en-US', { 
        year: 'numeric', 
        month: 'short', 
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    })}`;
    Object.assign(dateCell, styles.date);

    // Set row heights
    sheet.getRow(1).height = 25;
    sheet.getRow(2).height = 20;
    sheet.getRow(3).height = 15;
    sheet.getRow(4).height = 5; // Spacer

    // === Header Row ===
    const headerRow = sheet.getRow(5);
    headerRow.values = headers.map(h => h.toString().toUpperCase().replace(/_/g, ' '));
    Object.assign(headerRow, styles.header);
    headerRow.height = 20;

    // === Data Rows ===
    data.forEach((item, idx) => {
        const row = sheet.getRow(6 + idx);
        row.values = headers.map(h => {
            const value = item[h];
            if (value instanceof Date) {
                return value.toLocaleDateString();
            }
            return value !== undefined ? value : "";
        });
        Object.assign(row, styles.dataRow);
        
        // Alternate row coloring
        if (idx % 2 === 0) {
            row.fill = {
                type: 'pattern',
                pattern: 'solid',
                fgColor: { argb: 'FFF2F2F2' }
            };
        }
    });

    // === Column Sizing ===
    sheet.columns = headers.map((h, i) => ({
        key: h,
        header: h.toString().toUpperCase().replace(/_/g, ' '),
        width: Math.min(30, Math.max(15, h.length + 5)),
        style: {
            alignment: { 
                wrapText: true,
                vertical: 'middle'
            }
        }
    }));

    // === Final Sheet Setup ===
    sheet.views = [{
        state: 'frozen',
        ySplit: 5, // Freeze header row
        activeCell: 'A6'
    }];

    sheet.autoFilter = {
        from: { row: 5, column: 1 },
        to: { row: 5, column: headers.length }
    };

    sheet.properties.defaultRowHeight = 20;

    // === Save File ===
    try {
        await workbook.xlsx.writeFile(outputPath);
        console.log('Excel file generated successfully');
    } catch (err) {
        console.error('Error writing Excel file:', err);
        throw err;
    }
}

const [dataPath, outPath] = process.argv.slice(2); // Removed logoPath
generate(dataPath, outPath).catch(err => {
    console.error("Excel generation failed:", err);
    process.exit(1);
});