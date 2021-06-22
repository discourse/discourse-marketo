# discourse-marketo

Discourse plugin that automatically creates, updates or destroys Marketo leads that reflect Discourse users (only primary email address, name and trust level are used).

A lead will be created when users subscribe to receive newsletters. To do that, they will have to select the "Newsletter" user field from their preferences. Similarly, a lead will be deleted if the user unsubscribes or it is deleted.

To set up this plugin, an administrator will have to fill in all settings of this plugin, create a "Newsletter" user field of type `confirmation` (see `marketo newsletter field` site setting), and a Marketo field that stores the value of trust level (see `marketo trust level field` site setting).
