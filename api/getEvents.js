// /api/getEvents.js

const ical = require('node-ical');

module.exports = async (req, res) => {
    const calendarUrl = process.env.OUTLOOK_CALENDAR_URL;

    if (!calendarUrl) {
        return res.status(500).json({ error: 'Server configuration error: Calendar URL not found.' });
    }

    res.setHeader('Access-Control-Allow-Origin', '*');

    try {
        const events = await ical.async.fromURL(calendarUrl);
        const formattedEvents = [];

        for (const event of Object.values(events)) {
            if (event.type === 'VEVENT' && event.start) {
                const timeOptions = { hour: 'numeric', minute: '2-digit', hour12: true };
                const startTime = new Date(event.start).toLocaleTimeString('en-US', timeOptions).replace(' ', '');
                const endTime = event.end ? new Date(event.end).toLocaleTimeString('en-US', timeOptions).replace(' ', '') : '';

                // NEW: Logic to format the location and create a map link
                let displayLocation = event.location || 'No Location Provided';
                let mapLink = '#'; // Default to a non-functional link
                if (event.location) {
                    // Create the Google Maps link by URL-encoding the full address
                    mapLink = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(event.location)}`;
                    // Attempt to remove the zip code and country for a cleaner display
                    displayLocation = event.location.replace(/,?\s\d{5},?\sUnited States/g, '');
                }

                formattedEvents.push({
                    title: event.summary || 'No Title',
                    date: new Date(event.start).toISOString().split('T')[0],
                    time: event.end ? `${startTime} - ${endTime}` : startTime,
                    displayLocation: displayLocation, // Use the new clean version
                    mapLink: mapLink, // Add the new map link
                    description: event.description || 'No Description Provided.',
                });
            }
        }
        res.status(200).json(formattedEvents);
    } catch (error) {
        console.error('Failed to fetch or parse calendar data:', error);
        res.status(500).json({ error: 'Failed to retrieve calendar events.' });
    }
};