using System;

namespace Microsoft.Win32.Security
{
	using HANDLE = System.IntPtr;
	using DWORD = System.UInt32;

	/// <summary>
	///  Various herlper classes
	/// </summary>
	public sealed class Win32Helpers
	{
		private Win32Helpers()
		{
		}

		public static void GetSecurityInfo(
			HANDLE handle,
			SE_OBJECT_TYPE objectType,
			SECURITY_INFORMATION securityInfo,
			out Sid sidOwner,
			out Sid sidGroup,
			out Dacl dacl,
			out Sacl sacl,
			out SecurityDescriptor secDesc)
		{
			sidOwner = null;
			sidGroup = null;
			dacl = null;
			sacl = null;
			secDesc = null;

			IntPtr ptrOwnerSid = IntPtr.Zero;
			IntPtr ptrGroupSid = IntPtr.Zero;
			IntPtr ptrDacl = IntPtr.Zero;
			IntPtr ptrSacl = IntPtr.Zero;
			IntPtr ptrSecDesc = IntPtr.Zero;

			DWORD rc = Win32.GetSecurityInfo(handle, objectType, securityInfo,
				ref ptrOwnerSid, ref ptrGroupSid, ref ptrDacl, ref ptrSacl, ref ptrSecDesc);

			if (rc != Win32.ERROR_SUCCESS)
			{
				Win32.SetLastError(rc);
				Win32.ThrowLastError();
			}

			try
			{
				if (ptrOwnerSid != IntPtr.Zero)
					sidOwner = new Sid(ptrOwnerSid);

				if (ptrGroupSid != IntPtr.Zero)
					sidGroup = new Sid(ptrGroupSid);

				if (ptrDacl != IntPtr.Zero)
					dacl = new Dacl(ptrDacl);

				if (ptrSacl != IntPtr.Zero)
					sacl = new Sacl(ptrSacl);

				if (ptrSecDesc != IntPtr.Zero)
					secDesc = new SecurityDescriptor(ptrSecDesc, true);
			}
			catch
			{
				if (ptrSecDesc != IntPtr.Zero)
					Win32.LocalFree(ptrSecDesc);
				throw;
			}
		}
		public static void GetNamedSecurityInfo(
			string objectName,
			SE_OBJECT_TYPE objectType,
			SECURITY_INFORMATION securityInfo,
			out Sid sidOwner,
			out Sid sidGroup,
			out Dacl dacl,
			out Sacl sacl,
			out SecurityDescriptor secDesc)
		{
			sidOwner = null;
			sidGroup = null;
			dacl = null;
			sacl = null;
			secDesc = null;

			IntPtr ptrOwnerSid = IntPtr.Zero;
			IntPtr ptrGroupSid = IntPtr.Zero;
			IntPtr ptrDacl = IntPtr.Zero;
			IntPtr ptrSacl = IntPtr.Zero;
			IntPtr ptrSecDesc = IntPtr.Zero;

			DWORD rc = Win32.GetNamedSecurityInfo(objectName, objectType, securityInfo,
				ref ptrOwnerSid, ref ptrGroupSid, ref ptrDacl, ref ptrSacl, ref ptrSecDesc);

			if (rc != Win32.ERROR_SUCCESS)
			{
				Win32.SetLastError(rc);
				Win32.ThrowLastError();
			}

			try
			{
				if (ptrOwnerSid != IntPtr.Zero)
					sidOwner = new Sid(ptrOwnerSid);

				if (ptrGroupSid != IntPtr.Zero)
					sidGroup = new Sid(ptrGroupSid);

				if (ptrDacl != IntPtr.Zero)
					dacl = new Dacl(ptrDacl);

				if (ptrSacl != IntPtr.Zero)
					sacl = new Sacl(ptrSacl);

				if (ptrSecDesc != IntPtr.Zero)
					secDesc = new SecurityDescriptor(ptrSecDesc, true);
			}
			catch
			{
				if (ptrSecDesc != IntPtr.Zero)
					Win32.LocalFree(ptrSecDesc);
				throw;
			}
		}
		public static void SetSecurityInfo(
			HANDLE handle,
			SE_OBJECT_TYPE ObjectType,
			SECURITY_INFORMATION SecurityInfo,
			Sid sidOwner,
			Sid sidGroup,
			Dacl dacl,
			Sacl sacl)
		{
			UnsafeSetSecurityInfo (handle, ObjectType, SecurityInfo,
				sidOwner, sidGroup, dacl, sacl);
		}
		public static void SetNamedSecurityInfo(
			string objectName,
			SE_OBJECT_TYPE objectType,
			SECURITY_INFORMATION securityInfo,
			Sid sidOwner,
			Sid sidGroup,
			Dacl dacl,
			Sacl sacl)
		{
			UnsafeSetNamedSecurityInfo (objectName, objectType, securityInfo,
				sidOwner, sidGroup, dacl, sacl);
		}
		internal unsafe static void UnsafeSetSecurityInfo(
			HANDLE handle,
			SE_OBJECT_TYPE ObjectType,
			SECURITY_INFORMATION SecurityInfo,
			Sid sidOwner,
			Sid sidGroup,
			Dacl dacl,
			Sacl sacl)
		{
            bool validOwner = false;
            bool validGroup = false;
            bool validDacl = false;
            bool validSacl = false;

            try {validOwner = sidOwner.Equals(null);} 
            catch {;}
            try {validGroup = sidGroup.Equals(null);} 
            catch {;}
            try {validDacl = dacl.Equals(null);} 
            catch {;}
            try {validSacl = sacl.Equals(null);} 
            catch {;}

            fixed(byte *pSidOwner = (validOwner ? sidOwner.GetNativeSID() : null))
			{
				fixed(byte *pSidGroup = (validGroup ? sidGroup.GetNativeSID() : null))
				{
					fixed(byte *pDacl = (validDacl ? dacl.GetNativeACL() : null))
					{
						fixed(byte *pSacl = (validSacl ? sacl.GetNativeACL() : null))
						{
							DWORD rc = Win32.SetSecurityInfo(handle, ObjectType, SecurityInfo,
								(IntPtr)pSidOwner, (IntPtr)pSidGroup, (IntPtr)pDacl, (IntPtr)pSacl);
							if (rc != Win32.ERROR_SUCCESS)
							{
								Win32.SetLastError(rc);
								Win32.ThrowLastError();
							}
						}
					}
				}
			}
		}
		internal unsafe static void UnsafeSetNamedSecurityInfo(
			string objectName,
			SE_OBJECT_TYPE objectType,
			SECURITY_INFORMATION securityInfo,
			Sid sidOwner,
			Sid sidGroup,
			Dacl dacl,
			Sacl sacl)
		{

//            fixed(byte *pSidOwner = (validOwner ? sidOwner.GetNativeSID() : nullPtr))
//            {
//                fixed(byte *pSidGroup = (validGroup ? sidGroup.GetNativeSID() : nullPtr))
//                {
                    fixed(byte *pDacl = (dacl != null ? dacl.GetNativeACL() : null))
                    {
//                        fixed(byte *pSacl = (validSacl ? sacl.GetNativeACL() : null))
//                        {
                            DWORD rc = Win32.SetNamedSecurityInfo(objectName, objectType, securityInfo,
								(IntPtr)null, (IntPtr)null, (IntPtr)pDacl, (IntPtr)null);
							if (rc != Win32.ERROR_SUCCESS)
							{
								Win32.SetLastError(rc);
								Win32.ThrowLastError();
//							}
						}
					}
//				}
//			}
		}
	}
}
