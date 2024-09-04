/*************************************************************             
** File:   [GetManualJournalList]            
** Author:   Satish Gohil
** Description: This procedre 
** Purpose:           
** Date:   27/12/2022           
**************************************************************             
** Change History             
**************************************************************             
** PR   Date         Author			Change Description              
** --   --------     -------		--------------------------------            
	1   13/07/2023   Satish Gohil  Modify (add status filter)
	2   30/08/2023   Moin Bloch  Modify (add periodName filter)
	3   01/09/2023   Moin Bloch  Modify (add MULTIPLE FILTERS filters)
	4   04/09/2023   Moin Bloch  Modify (filters changes )
	5   08/09/2023   Moin Bloch  Modify (Added Distinct to prevent duplicate records)
	6   27/11/2023   Bhargav Saliya     Utc Date Changes
	7   04/09/2024   AMIT GHEDIYA     Modify (Get Debit & Credit Fields)
    
**************************************************************/  

CREATE     PROCEDURE [dbo].[GetManualJournalList]  
 -- Add the parameters for the stored procedure here  
 @PageNumber int,  
 @PageSize int,  
 @SortColumn varchar(50)=null,  
 @SortOrder int,  
 @StatusID int,  
 @GlobalFilter varchar(50) = null,  
 @JournalNumber varchar(50)=null,  
 @LedgerName varchar(50)=null,  
 @JournalDescription varchar(250)=null,  
 @PeriodName varchar(50) = null,  
 @Recuring varchar(10) = null,  
 @Reversing varchar(10) = null,  
 @lastMSLevel varchar(50)=null,
 @ManualType varchar(50)=null,  
 @ManualJournalBalanceType varchar(50)=null,  
 @EntryDate datetime=null,  
 @EffectiveDate datetime=null,  
 @ManualJournalStatus varchar(50)=null,  
 @CreatedDate datetime=null,  
 @UpdatedDate  datetime=null,  
 @IsDeleted bit = null,  
 @CreatedBy varchar(50)=null,  
 @UpdatedBy varchar(50)=null,  
 @MasterCompanyId int = null,  
 @EmployeeId bigint,
 @TotalDebit varchar(50)= null,      
 @TotalCredit varchar(50)=null
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
  --BEGIN TRANSACTION  
  -- BEGIN  
    DECLARE @RecordFrom int;  
    SET @RecordFrom = (@PageNumber-1) * @PageSize;  
    IF @IsDeleted IS NULL  
    BEGIN  
     SET @IsDeleted=0  
    END  
    IF @SortColumn IS NULL  
    BEGIN  
     SET @SortColumn=UPPER('CreatedDate')  
    END   
    ELSE  
    BEGIN   
     SET @SortColumn=UPPER(@SortColumn)  
    END  
    
    If @StatusID=0  
    BEGIN   
     SET @StatusID=NULL  
    END   
  

    DECLARE @EmpLegalEntiyId BIGINT = 0;
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

	SELECT @EmpLegalEntiyId = LegalEntityId FROM DBO.Employee WHERE EmployeeId = @EmployeeId;
	SELECT @CurrntEmpTimeZoneDesc = TZ.[Description] FROM DBO.LegalEntity LE WITH (NOLOCK) INNER JOIN DBO.TimeZone TZ WITH (NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId 
	WHERE LE.LegalEntityId = @EmpLegalEntiyId;

	IF(@CreatedDate IS NOT NULL)
	BEGIN
    SET @CreatedDate = CONVERT(DATETIME,@CreatedDate AT TIME ZONE @CurrntEmpTimeZoneDesc AT TIME ZONE 'UTC');
	END  

	IF(@UpdatedDate IS NOT NULL)
	BEGIN
    SET @UpdatedDate = CONVERT(DATETIME,@UpdatedDate AT TIME ZONE @CurrntEmpTimeZoneDesc AT TIME ZONE 'UTC');
	END

	IF(@EntryDate IS NOT NULL)
	BEGIN
    SET @EntryDate = CONVERT(DATETIME,@EntryDate AT TIME ZONE @CurrntEmpTimeZoneDesc AT TIME ZONE 'UTC');
	END


    --If @Status='0'  
    --Begin  
    -- Set @Status=null  
    --End  
    DECLARE @MSModuleID INT = 64; -- Sales Order Management Structure Module ID  
   -- Insert statements for procedure here  
   ;With Result AS(  
		SELECT DISTINCT MJH.ManualJournalHeaderId, 
		       MJH.JournalNumber, 
			   MJH.LedgerId, 
			   L.LedgerName AS 'LedgerName', 
			   MJH.JournalDescription,
			   MJH.ManualJournalTypeId,
			   MJT.[Name] AS ManualType,  
			   MJH.ManualJournalBalanceTypeId,
			   MJBT.[Name] AS ManualJournalBalanceType,			   			  
			   MJH.EntryDate,
			   MJH.EffectiveDate,
			   MJH.AccountingPeriodId,
			   Ac.PeriodName,
			   MJH.ManualJournalStatusId,
			   MJS.[Name] AS ManualJournalStatus,  
			   MJH.ManagementStructureId,
			   MJH.EmployeeId,
			   E.FirstName + ' ' + E.LastName as UserName,
			   MJH.CreatedBy,
			   MJH.UpdatedBy,			   			   
			   MJH.CreatedDate,
			   MJH.UpdatedDate,
			   CASE WHEN MJH.IsRecuring = 1 THEN 1 ELSE 0 END AS IsRecuring,  
			   CASE WHEN MJH.IsRecuring = 2 THEN 1 ELSE 0 END AS IsReversing,
			   CASE WHEN MJH.IsRecuring = 1 THEN 'YES' ELSE 'NO' END AS Recuring,  
			   CASE WHEN MJH.IsRecuring = 2 THEN 'YES' ELSE 'NO' END AS Reversing,
			   MSD.LastMSLevel,
			   MSD.AllMSlevels,
			   Debit = (SELECT ISNULL(SUM(Debit),0) FROM ManualJournalDetails MJD 
						WHERE MJD.ManualJournalHeaderId = MJH.ManualJournalHeaderId 
						AND MJD.IsActive = 1 AND MJD.IsDeleted = 0
						),
			   Credit = (SELECT ISNULL(SUM(Credit),0) FROM ManualJournalDetails MJD 
						WHERE MJD.ManualJournalHeaderId = MJH.ManualJournalHeaderId 
			   AND MJD.IsActive = 1 
			   AND MJD.IsDeleted = 0)
			FROM [dbo].[ManualJournalHeader] MJH WITH (NOLOCK)  
			INNER JOIN [dbo].[Ledger] L WITH (NOLOCK) ON MJH.LedgerId = L.LedgerId  
			INNER JOIN [dbo].[ManualJournalType] MJT WITH (NOLOCK) ON MJH.ManualJournalTypeId = MJT.ManualJournalTypeId  
			 LEFT JOIN [dbo].[ManualJournalBalanceType] MJBT WITH (NOLOCK) ON MJH.ManualJournalBalanceTypeId = MJBT.ManualJournalBalanceTypeId  
			INNER JOIN [dbo].[AccountingCalendar] Ac WITH (NOLOCK) ON MJH.AccountingPeriodId = Ac.AccountingCalendarId  
			 LEFT JOIN [dbo].[ManualJournalStatus] MJS WITH (NOLOCK) ON MJH.ManualJournalStatusId = MJS.ManualJournalStatusId  
			 LEFT JOIN [dbo].Employee E WITH (NOLOCK) on  E.EmployeeId = MJH.EmployeeId  
			INNER JOIN [dbo].[AccountingManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = MJH.ManualJournalHeaderId  
			INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON MJH.ManagementStructureId = RMS.EntityStructureId  
			INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId  
			WHERE (MJH.IsDeleted = @IsDeleted)   
			AND (@StatusID IS NULL OR MJH.ManualJournalStatusId = @StatusID)  
			AND MJH.MasterCompanyId = @MasterCompanyId     
    ),  
    FinalResult AS (  
    SELECT ManualJournalHeaderId, JournalNumber, LedgerId, LedgerName, JournalDescription,ManualJournalTypeId,ManualType,  
      ManualJournalBalanceTypeId,ManualJournalBalanceType,EntryDate,EffectiveDate,  
      AccountingPeriodId,PeriodName,ManualJournalStatusId,ManualJournalStatus,  
      ManagementStructureId,EmployeeId,UserName,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsRecuring,IsReversing,Recuring,Reversing, LastMSLevel,AllMSlevels,Debit,Credit FROM Result  
    WHERE (  
     (@GlobalFilter <>'' AND ((JournalNumber LIKE '%' +@GlobalFilter+'%' ) OR   
       (LedgerName LIKE '%' +@GlobalFilter+'%') OR  
	   (JournalDescription LIKE '%' +@GlobalFilter+'%') OR  
	   (periodName LIKE '%' +@GlobalFilter+'%') OR
	   (Recuring LIKE '%' +@GlobalFilter+'%') OR
	   (Reversing LIKE '%' +@GlobalFilter+'%') OR
       (LastMSLevel LIKE '%' +@GlobalFilter+'%') OR
       (EntryDate LIKE '%' +@GlobalFilter+'%') OR  
	   (CreatedBy LIKE '%' +@GlobalFilter+'%') OR  
	   (UpdatedBy LIKE '%' +@GlobalFilter+'%') OR  
       (ManualType LIKE '%' +@GlobalFilter+'%') OR  
       (ManualJournalBalanceType LIKE '%'+@GlobalFilter+'%') OR  
       (ManualJournalStatus LIKE '%' +@GlobalFilter+'%')  
       ))  
       OR     
       (@GlobalFilter='' AND (ISNULL(@JournalNumber,'') ='' OR JournalNumber LIKE  '%'+ @JournalNumber+'%') AND   
       (ISNULL(@LedgerName,'') ='' OR LedgerName LIKE '%'+@LedgerName+'%') AND  
	   (ISNULL(@JournalDescription,'') ='' OR JournalDescription LIKE '%'+@JournalDescription+'%') AND  
	   (ISNULL(@PeriodName,'') ='' OR periodName LIKE '%'+ @PeriodName +'%') AND  
	   (ISNULL(@Recuring,'') ='' OR Recuring LIKE '%'+ @Recuring +'%') AND  
	   (ISNULL(@Reversing,'') ='' OR Reversing LIKE '%'+ @Reversing +'%') AND  
	   (ISNULL(@lastMSLevel,'') ='' OR LastMSLevel LIKE '%'+ @lastMSLevel +'%') AND 
       (ISNULL(@ManualType,'') ='' OR ManualType LIKE  '%'+@ManualType+'%') AND  
       (ISNULL(@ManualJournalBalanceType,'') ='' OR ManualJournalBalanceType LIKE  '%'+@ManualJournalBalanceType+'%') AND  
       (ISNULL(@ManualJournalStatus,'') ='' OR ManualJournalStatus LIKE '%'+ @ManualJournalStatus+'%') AND  
       (ISNULL(@EntryDate,'') ='' OR CAST(EntryDate AS DATE) = CAST(@EntryDate AS DATE)) AND  
       (ISNULL(@EffectiveDate,'') ='' OR CAST(EffectiveDate AS DATE) = CAST(@EffectiveDate AS DATE)) AND  
       (ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%'+ @CreatedBy+'%') AND  
       (ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%'+ @UpdatedBy+'%') AND  
       (ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS DATE)= CAST(@CreatedDate AS DATE)) AND  
       (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS DATE)= CAST(@UpdatedDate AS DATE)) AND
	   (IsNull(@TotalDebit,'') ='' OR CAST(Debit AS varchar(20)) like '%' + @TotalDebit+'%' ) AND       
	   (IsNull(@TotalCredit,'') ='' OR CAST(Credit AS varchar(20)) like '%' + @TotalCredit+'%' ))  
       )), 
	   
      ResultCount AS (SELECT COUNT(ManualJournalHeaderId) AS NumberOfItems FROM FinalResult)  
      SELECT ManualJournalHeaderId, JournalNumber, LedgerId, LedgerName, JournalDescription,ManualJournalTypeId,ManualType,  
      ManualJournalBalanceTypeId,ManualJournalBalanceType,EntryDate,EffectiveDate,  
      AccountingPeriodId,PeriodName,ManualJournalStatusId,ManualJournalStatus,  
      ManagementStructureId,EmployeeId,UserName,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsRecuring,IsReversing,Recuring,Reversing,LastMSLevel,AllMSlevels,Debit,Credit, NumberOfItems FROM FinalResult, ResultCount  
  
     ORDER BY    
     CASE WHEN (@SortOrder=1 AND @SortColumn='MANUALJOURNALHEADERID')  THEN ManualJournalHeaderId END DESC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='JOURNALNUMBER')  THEN JournalNumber END ASC,  
	 CASE WHEN (@SortOrder=1 AND @SortColumn='LEDGERNAME')  THEN LEDGERNAME END ASC, 
	 CASE WHEN (@SortOrder=1 AND @SortColumn='JOURNALDESCRIPTION')  THEN JOURNALDESCRIPTION END ASC,  	
	 CASE WHEN (@SortOrder=1 AND @SortColumn='MANUALJOURNALSTATUS')  THEN MANUALJOURNALSTATUS END ASC,   
	 CASE WHEN (@SortOrder=1 AND @SortColumn='ENTRYDATE')  THEN EntryDate END ASC,   
	 CASE WHEN (@SortOrder=1 AND @SortColumn='EFFECTIVEDATE')  THEN effectiveDate END ASC,   
	 CASE WHEN (@SortOrder=1 AND @SortColumn='RECURING')  THEN Recuring END ASC, 
	 CASE WHEN (@SortOrder=1 AND @SortColumn='REVERSING')  THEN Reversing END ASC, 
	 CASE WHEN (@SortOrder=1 AND @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC, 	 
	 CASE WHEN (@SortOrder=1 AND @SortColumn='PERIODNAME')  THEN JournalNumber END ASC, 
     CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
	 CASE WHEN (@SortOrder=1 and @SortColumn='DEBIT')  THEN CAST(Debit AS varchar(20)) END ASC,        
	 CASE WHEN (@SortOrder=1 and @SortColumn='CREDIT')  THEN CAST(Credit AS varchar(20)) END ASC, 
  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='MANUALJOURNALHEADERID')  THEN ManualJournalHeaderId END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='JOURNALNUMBER')  THEN JournalNumber END DESC,  
	 CASE WHEN (@SortOrder=-1 AND @SortColumn='LEDGERNAME')  THEN LEDGERNAME END DESC,  
	 CASE WHEN (@SortOrder=-1 AND @SortColumn='JOURNALDESCRIPTION')  THEN JOURNALDESCRIPTION END DESC, 
	 CASE WHEN (@SortOrder=-1 AND @SortColumn='MANUALJOURNALSTATUS')  THEN MANUALJOURNALSTATUS END DESC, 
	 CASE WHEN (@SortOrder=-1 AND @SortColumn='ENTRYDATE')  THEN EntryDate END DESC,   
	 CASE WHEN (@SortOrder=-1 AND @SortColumn='EFFECTIVEDATE')  THEN effectiveDate END DESC,   
	 CASE WHEN (@SortOrder=-1 AND @SortColumn='RECURING')  THEN Recuring END DESC,  
	 CASE WHEN (@SortOrder=-1 AND @SortColumn='REVERSING')  THEN Reversing END DESC,  
	 CASE WHEN (@SortOrder=-1 AND @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC, 
	 CASE WHEN (@SortOrder=-1 AND @SortColumn='PERIODNAME')  THEN JournalNumber END DESC, 
     CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC, 
	 CASE WHEN (@SortOrder=-1 and @SortColumn='DEBIT')  THEN CAST(Debit AS varchar(20))  END Desc,        
	 CASE WHEN (@SortOrder=-1 and @SortColumn='CREDIT')  THEN CAST(Credit AS varchar(20)) END Desc        
     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
   -- END  
   --COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    --ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'GetManualJournalList'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END