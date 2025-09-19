// /api/getEvents.js

const ical = require('node-ical');

module.exports = async (req, res) => {
    const calendarUrl = process.env.OUTLOOK_CALENDAR_URL;

    if (!calendarUrl) {
        return res.status(500).json({ error: 'Server configuration error: Calendar URL not found.' });
    }

    // --- NEW LINE ADDED HERE ---
    // This header tells browsers that any website (*) is allowed to request data from this function.
    res.setHeader('Access-Control-Allow-Origin', '*');

    try {
        const events = await ical.async.fromURL(calendarUrl);
        const formattedEvents = [];

        for (const event of Object.values(events)) {
            if (event.type === 'VEVENT' && event.start) {
                const timeOptions = { hour: 'numeric', minute: '2-digit', hour12: true };
                const startTime = new Date(event.start).toLocaleTimeString('en-US', timeOptions).replace(' ', '');
                const endTime = event.end ? new Date(event.end).toLocaleTimeString('en-US', timeOptions).replace(' ', '') : '';

                formattedEvents.push({
                    title: event.summary || 'No Title',
                    date: new Date(event.start).toISOString().split('T')[0],
                    time: event.end ? `${startTime} - ${endTime}` : startTime,
                    location: event.location || 'No Location Provided',
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