function getObjectById(documentId)
{
   if (document.getElementById)
   {
      return document.getElementById(documentId);
   }
   else if (document.all)
   {
      return document.all[documentId];
   }
   else if (document.layers)
   {
      return document.layers[documentId];
   }
   else
   {
      return null;
   }
}

