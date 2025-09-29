# Clean URLs Setup Instructions

## What This Does
This setup allows your website to use clean URLs without the `.html` extension. For example:
- `GreatFallsPoliceSC.com/recruitment` instead of `GreatFallsPoliceSC.com/recruitment.html`
- `GreatFallsPoliceSC.com/contact` instead of `GreatFallsPoliceSC.com/contact.html`

## Files You Need to Upload

### 1. .htaccess File
Upload the `.htaccess` file to your website's root directory (the same folder where your `index.html` is located).

**Important:** Make sure the file is named exactly `.htaccess` (with the dot at the beginning and no file extension).

### 2. Updated HTML Files
Upload all the updated HTML files:
- `index.html`
- `contact.html`
- `events.html`
- `recruitment.html`
- `resources.html`
- `application.html`

## How to Upload via cPanel

1. **Log into your cPanel**
2. **Go to File Manager**
3. **Navigate to your website's root directory** (usually `public_html`)
4. **Upload the .htaccess file:**
   - Click "Upload" in File Manager
   - Select the `.htaccess` file
   - Make sure it uploads to the root directory
5. **Upload the updated HTML files:**
   - Upload each HTML file, replacing the existing ones
6. **Set proper permissions:**
   - Right-click on `.htaccess` → "Change Permissions"
   - Set to 644 (readable by web server)

## Testing

After uploading, test these URLs:
- `GreatFallsPoliceSC.com/` (home page)
- `GreatFallsPoliceSC.com/contact`
- `GreatFallsPoliceSC.com/events`
- `GreatFallsPoliceSC.com/recruitment`
- `GreatFallsPoliceSC.com/resources`

## Troubleshooting

### If clean URLs don't work:
1. **Check .htaccess file:** Make sure it's in the root directory and named correctly
2. **Check permissions:** Ensure .htaccess has 644 permissions
3. **Check server support:** Some shared hosting may not support .htaccess. Contact your hosting provider if needed.

### If you get 500 errors:
- The .htaccess file might have syntax errors
- Check your cPanel error logs for specific error messages

### Alternative Method (if .htaccess doesn't work):
If your hosting doesn't support .htaccess, you can use the directory method:
1. Create folders: `recruitment/`, `contact/`, `events/`, `resources/`
2. Move each HTML file into its respective folder and rename to `index.html`
3. This will make URLs work as `GreatFallsPoliceSC.com/recruitment/`

## What Changed

All internal links in your website have been updated to use clean URLs:
- Navigation menus
- Footer links
- Quick action buttons
- Form redirects

The `.htaccess` file automatically handles the URL rewriting so visitors can access pages with or without the `.html` extension.
