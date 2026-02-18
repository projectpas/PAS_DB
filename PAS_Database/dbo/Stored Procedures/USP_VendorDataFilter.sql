/*******************************************************************************************
 ** File:   [USP_VendorDataFilter]          
 ** Author:  Ayushi Patel
 ** Description: Returns Vendor Data 
 ** Purpose:         
 ** Date:   09/05/2025      
          
 ** PARAMETERS: 
    @FilterVal NVARCHAR(100),
    @Count INT,
    @IdList NVARCHAR(MAX),
    @MasterCompanyId INT
         
 ** RETURN VALUE:          
 *******************************************************************************************           
 ** Change History           
 *******************************************************************************************           
 ** PR   Date         Author		        Change Description            
 ** --   --------     -------		    --------------------------------          
    1    09/05/2025  Ayushi Patel	    Created
    2    13/02/2026  Ayushi Patel       Added duplicate VendorName logic to check across full table and return DisplayName with VendorCode when duplicates exist.
-- EXEC [USP_VendorDataFilter] null , 0 , '0' , 1
********************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_VendorDataFilter]
    @FilterVal NVARCHAR(100),
    @Count INT,
    @IdList NVARCHAR(MAX),
    @MasterCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF (@FilterVal IS NULL)
            SET @FilterVal = '';
        IF (@IdList IS NULL)
            SET @IdList = '0';
        IF (@Count = 0)
            SET @Count = 20;

        ;WITH FilteredVendors AS (
            SELECT TOP (@Count)
                VendorId,
                VendorName,
                VendorCode,
                IsVendorOnHold
            FROM DBO.Vendor WITH (NOLOCK)
            WHERE ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0
              AND MasterCompanyId = @MasterCompanyId
              AND LOWER(VendorName) LIKE '%' + LOWER(@FilterVal) + '%'
        ),
        IdBasedVendors AS (
            SELECT TOP (@Count)
                VendorId,
                VendorName,
                VendorCode,
                IsVendorOnHold
            FROM DBO.Vendor WITH (NOLOCK)
            WHERE MasterCompanyId = @MasterCompanyId
              AND CAST(VendorId AS NVARCHAR) IN (
                  SELECT value FROM STRING_SPLIT(@IdList, ',')
              )
        ),
        Combined AS (
            SELECT * FROM FilteredVendors
            UNION
            SELECT * FROM IdBasedVendors
        ),

        NameCounts AS (
            SELECT 
                VendorName,
                COUNT(*) AS NameCount
            FROM dbo.Vendor WITH (NOLOCK)
            WHERE ISNULL(IsActive,0) = 1 
              AND ISNULL(IsDeleted,0) = 0
              AND MasterCompanyId = @MasterCompanyId
            GROUP BY VendorName
        )

        SELECT 
            C.VendorId,
            C.VendorName,
            C.VendorCode,
            C.IsVendorOnHold,
            CASE 
                WHEN NC.NameCount > 1 
                    THEN C.VendorName + ' - ' + C.VendorCode
                ELSE C.VendorName
            END AS DisplayName
        FROM Combined C
        LEFT JOIN NameCounts NC 
            ON C.VendorName = NC.VendorName
        ORDER BY C.VendorName;
    END TRY
    BEGIN CATCH
   DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'USP_VendorDataFilter'
            , @ProcedureParameters VARCHAR(3000)  = ''  
            , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
            exec spLogException   
                    @DatabaseName   = @DatabaseName  

                    , @AdhocComments   = @AdhocComments  
                    , @ProcedureParameters  = @ProcedureParameters  
                    , @ApplicationName   =  @ApplicationName  
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;  
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
            RETURN(1);  
    END CATCH
END