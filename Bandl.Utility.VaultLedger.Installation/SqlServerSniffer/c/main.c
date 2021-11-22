#include <windows.h>
#include <sql.h>
#include "string.h"
#include "stdio.h"
#include <sqlext.h>
#include <odbcss.h>

static void CheckForLocalMachine(char* returnBuffer);
static BOOL ContainsString(char* string1, char* string2, BOOL caseSensitive);
static BOOL SqlServerExists( void );

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//
// DllMain - entry point for library
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
int WINAPI DllMain( HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved )
{
    return TRUE;
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//
// CheckForLocalMachine 
//
// Makes sure that the local machine is in the list if it should be
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
static void CheckForLocalMachine(char* returnBuffer)
{
    char computerName[512];
    char tempBuffer[2048];
    int nameSize = 512;

    if (strstr(returnBuffer, "(local)") != NULL)
    {
        return;
    }
    else
    {
        memset(computerName, 0, sizeof(computerName));
        GetComputerName(computerName, &nameSize);
        // If the string contains the computer name, then return
        if (ContainsString(returnBuffer, computerName, FALSE))
        {
            return;
        }
    }
    // Local machine not found in string...does this 
    // machine have sql server installed?
    if (SqlServerExists() == TRUE)
    {
        sprintf(tempBuffer, "(local)%s", strlen(returnBuffer) != 0 ? "," : "");
        strcat(tempBuffer, returnBuffer);
        strcpy(returnBuffer, tempBuffer);
    }
}
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//
// ContainsString
//
// Returns 1 if the second string is contained within the first, else 0
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
static BOOL ContainsString(char* string1, char* string2, BOOL caseSensitive)
{
    char* temp1 = NULL;
    char* temp2 = NULL;
    char* p1;
    char* p2;
    UINT i = -1;
    BOOL r = FALSE;

    if (string1 == NULL || string2 == NULL)
    {
        return FALSE;
    }
    else if (caseSensitive == TRUE)
    {
        return strstr(string1, string2) != NULL;
    }
    else
    {
        temp1 = malloc(strlen(string1) + 1);
        temp2 = malloc(strlen(string2) + 1);
        memset(temp1, 0, strlen(string1) + 1);
        memset(temp2, 0, strlen(string2) + 1);
        // Copy the first string in lowercase
        p1 = string1;
        p2 = temp1;
        for (i = 0; i < strlen(string1); i += 1)
        {
           *p2 = tolower(*p1);
            p1 += 1;
            p2 += 1;
        }
        // Copy the second string in lowercase
        p1 = string2;
        p2 = temp2;
        for (i = 0; i < strlen(string2); i += 1)
        {
           *p2 = tolower(*p1);
            p1 += 1;
            p2 += 1;
        }
        // Search for the string
        r = strstr(temp1, temp2) != NULL;
        // Free the buffers
        free(temp1);
        free(temp2);
        // Return
        return r;
    }
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//
// GetServers - exported function that returns sql server instances
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
__declspec(dllexport) void GetServers(char* returnBuffer, int bufferSize)
{
   SQLHENV environmentHandle = SQL_NULL_HENV;
   SQLHDBC connectionHandle = SQL_NULL_HDBC;
   char inConnection[32];
   char outConnection[1024];
   short outLen;
   char *ptr1;
   char *ptr2;
   // Initialize the buffers
   memset(returnBuffer, 0, bufferSize);
   strcpy(inConnection, "DRIVER=SQL SERVER");
   memset(outConnection, 0, sizeof(outConnection));
   // Get the instances
   if (SQL_SUCCESS == SQLAllocHandle(SQL_HANDLE_ENV, NULL, &environmentHandle))
      if (SQL_SUCCESS == SQLSetEnvAttr(environmentHandle, SQL_ATTR_ODBC_VERSION, (SQLPOINTER)SQL_OV_ODBC3, 0))
         if (SQL_SUCCESS == SQLAllocHandle(SQL_HANDLE_DBC, environmentHandle, &connectionHandle))
            SQLBrowseConnect(connectionHandle, inConnection, (short)strlen(inConnection), outConnection, 1024, &outLen);
   // Free the handles
   if (connectionHandle != SQL_NULL_HDBC)
      SQLFreeHandle(SQL_HANDLE_DBC, connectionHandle);
   if (environmentHandle != SQL_NULL_HENV)
      SQLFreeHandle(SQL_HANDLE_ENV, environmentHandle);
   // Return only the servers
   if (strlen(outConnection) != 0)
   {
      ptr1 = strchr(outConnection, '{') + 1;
      ptr2 = strchr(outConnection, '}');
      strncpy(returnBuffer, ptr1, ptr2 - ptr1);
   }
   // Check for the local machine
   CheckForLocalMachine(returnBuffer);
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//
// SqlServerExists
//
// Finds sql server on the local machine
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
static BOOL SqlServerExists( void )
{
    HKEY key;
    DWORD index;
    char keyName[256];
    DWORD nameSize = 256;
    char fiveChars[6];

    // Initialize
    index = 0;
    memset(keyName, 0, sizeof(keyName));
    // Open the java runtime environment key
    if (ERROR_SUCCESS != RegOpenKeyEx(HKEY_LOCAL_MACHINE, "SYSTEM\\CurrentControlSet\\Services", 0, KEY_ALL_ACCESS, &key))
    {
        return FALSE;
    }
    // Run through the subkeys, looking for MSSQL
    while (ERROR_SUCCESS == RegEnumKeyEx(key, index, keyName, &nameSize, NULL, NULL, NULL, NULL))
    {
        // Does the key start with MSSQL?
        if (nameSize >= 5)
        {
            memset(fiveChars, 0, sizeof(fiveChars));
            strncpy(fiveChars, keyName, 5);
            if (ContainsString(fiveChars, "MSSQL", FALSE))
            {
                RegCloseKey(key);
                return TRUE;
            }
        }
        // Reinitialize
        memset(keyName, 0, sizeof(keyName));
        nameSize = 256;
        // Increment index
        index += 1;
    }
    // No MSSQL service found
    return FALSE;
}
