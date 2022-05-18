
/*************************************************************           
 ** File:   [sp_GetCustomerInvoicedatabyInvoiceId]           
 ** Author:   Subhash Saliya
 ** Description: Get Customer Invoicedataby InvoiceId   
 ** Purpose:         
 ** Date:   18-april-2022        
          
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/18/2022   Subhash Saliya Created
	
 -- exec sp_GetCustomerInvoicedatabyInvoiceId 92,1    
**************************************************************/ 


CREATE PROCEDURE [dbo].[USP_SearchCustomerRMAData]
@PageSize int,  
@PageNumber int,  
@SortColumn varchar(50),  
@SortOrder int, 
@GlobalFilter varchar(50)=null,
@StatusID int,  
@RMANumber	varchar(50),
@OpenDate datetime=null,
@RMAReason varchar(50),
@RMAStatus varchar(50),
@ValidDate datetime=null,
@ReturnDate datetime=null,
@CustomerName varchar(50),
@PartNumber		varchar(50),
@PartDescription varchar(50),
@ReferenceNo varchar(50),
@Qty	varchar(50),
@UnitPrice varchar(50),
@Amount varchar(50),
@Requestedby varchar(50),
@LastMSLevel varchar(50),
@MasterCompanyId int,
@ViewType varchar(10),
@EmployeeId bigint=1,
@IsDeleted bit,
@Memo varchar(50),
@ModuleID varchar(500)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		
	  DECLARE @RecordFrom int; 
	  Declare @IsActive bit = 1  
	  Declare @Count Int;  
	  SET @RecordFrom = (@PageNumber - 1) * @PageSize;

	  if(@GlobalFilter is null)
	  begin
	  set @GlobalFilter='';
	  end

	  IF @SortColumn is null  
	  Begin  
	   Set @SortColumn = 'RMANumber'  
	  End   
	  Else  
	  Begin   
	   Set @SortColumn = Upper(@SortColumn)  
	  End

	   IF LOWER(@ViewType) = 'mpn'  
       BEGIN 
	   
       SELECT COUNT(1) OVER () AS NumberOfItems,  
			 CRH.[RMAHeaderId] as RMAHeaderId
			,CRH.[RMANumber]
			,CRH.[CustomerId]
			,CRH.[CustomerName]
			,CRH.[CustomerCode]
			,CRH.[CustomerContactId]
			,CRH.[ContactInfo]
			,CRH.[OpenDate]
			,CRH.[InvoiceNo]
			,CRH.[InvoiceDate]
			,CRH.[RMAStatusId]
			,CRH.[RMAStatus]
			,CRH.[Iswarranty]
			,CRH.[ValidDate]
			,CRH.Requestedby
			,CRH.[ApprovedbyId]
			,CRH.[Approvedby]
			,CRH.[ApprovedDate]
			,CRH.[ReturnDate]
			,CRH.[WorkorderNum]
			,CRH.[WorkOrderId]
			,CRH.[ManagementStructureId]
			,CRH.[Memo] as Memo
			,CRH.[MasterCompanyId]
			,CRH.[CreatedBy]
			,CRH.[UpdatedBy]
			,CRH.[CreatedDate]
			,CRH.[UpdatedDate]
			,CRH.[IsActive]
			,CRH.[IsDeleted]
			,CRD.RMADeatilsId
			,CRD.[ItemMasterId]
			,CRD.[PartNumber]
			,CRD.[PartDescription]
			,CRD.[AltPartNumber]
			,CRD.[CustPartNumber]
			,CRD.[SerialNumber]
			,CRD.[StocklineNumber]
			,CRD.[ControlNumber]
			,CRD.[ControlId]
			,CRD.[ReferenceNo]
			,CRD.[isWorkOrder]
			,isnull(CRD.[Qty],0) as [Qty]
			,isnull(CRD.[UnitPrice],0) as [UnitPrice]
			,isnull(CRD.[Amount],0) as [Amount]
			,RMAR.Reason as[RMAReason]
			,MSD.LastMSLevel
			,MSD.AllMSlevels
			,CRH.ReferenceId
			,CM.CreditMemoHeaderId
        FROM CustomerRMAHeader CRH WITH(NOLOCK)  
        LEFT JOIN dbo.CustomerRMADeatils CRD WITH(NOLOCK) ON CRD.RMAHeaderId = CRH.RMAHeaderId 
		LEFT JOIN dbo.RMAReason RMAR WITH(NOLOCK) ON CRD.RMAReasonId = RMAR.RMAReasonId 
		INNER JOIN dbo.RMACreditMemoManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = CRH.RMAHeaderId
	    INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON CRH.ManagementStructureId = RMS.EntityStructureId
	    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId	
		 LEFT JOIN dbo.CreditMemo CM WITH(NOLOCK) ON CM.RMAHeaderId = CRH.RMAHeaderId 
        WHERE ((CRH.MasterCompanyId = @MasterCompanyId) AND (CRH.IsDeleted = @IsDeleted) AND (@StatusID=0 or CRH.RMAStatusId = @StatusID))  
       AND (  
        (@GlobalFilter <>'' AND (  
        (CRH.RMANumber like '%' +@GlobalFilter+'%') OR  
        (CRH.CustomerName like '%' +@GlobalFilter+'%') OR  
        (RMAStatus like '%' +@GlobalFilter+'%') OR  
        (CRH.Requestedby like '%' +@GlobalFilter+'%') OR  
        (CRH.[Memo] like '%'+@GlobalFilter+'%') OR  
        (PartNumber like '%'+@GlobalFilter+'%') OR  
        (PartDescription like '%' +@GlobalFilter+'%') OR  
		(ReferenceNo like '%' +@GlobalFilter+'%') OR 
		(CAST(Qty AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR	
		(CAST(UnitPrice AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR	
		(CAST(Amount AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR	
        (RMAReason like '%' +@GlobalFilter+'%')  
        ))  
        OR     
        (@GlobalFilter='' AND (IsNull(@RMANumber,'') ='' OR CRH.RMANumber like '%' + @RMANumber+'%') AND  
        (IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND  
        (IsNull(@PartDescription,'') ='' OR PartDescription like '%' + @PartDescription+'%') AND  
        (IsNull(@CustomerName,'') ='' OR CRH.CustomerName like '%' + @CustomerName+'%') AND  
		(IsNull(@OpenDate,'') ='' OR Cast(OpenDate as Date)=Cast(@OpenDate as date)) AND  
		(IsNull(@ValidDate,'') ='' OR Cast(ValidDate as Date)=Cast(@ValidDate as date)) AND  
	    (IsNull(@ReturnDate,'') ='' OR Cast(CRH.ReturnDate as Date)=Cast(@ReturnDate as date)) AND 
        (IsNull(@RMAStatus,'') ='' OR RMAStatus like '%' + @RMAStatus+'%') AND  
        (IsNull(@Memo,'') ='' OR CRH.[Memo] like '%' + @Memo+'%') AND
		(IsNull(@ReferenceNo,'') ='' OR ReferenceNo like '%' + @ReferenceNo+'%') AND  
	    (IsNull(@Qty,'') ='' OR  Qty like '%' + @Qty+'%') AND 
		(IsNull(@UnitPrice,'') ='' OR UnitPrice= @UnitPrice) AND 
		(IsNull(@Amount,'') ='' OR Amount = @Amount) AND    
		(IsNull(@Requestedby,'') ='' OR CRH.Requestedby like '%' + @Requestedby+'%') AND 
		(IsNull(@RMAReason,'') ='' OR RMAReason like '%' + @RMAReason+'%')  
        )
		)  
        ORDER BY    
        CASE WHEN (@SortOrder=1 and @SortColumn='RMANumber')  THEN CRH.RMANumber END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='PartNumber')  THEN PartNumber END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='PartDescription')  THEN PartDescription END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='CustomerName')  THEN CRH.CustomerName END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='OpenDate')  THEN OpenDate END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='ValidDate')  THEN ValidDate END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='RMAStatus')  THEN RMAStatus END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='Requestedby')  THEN CRH.Requestedby END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='ReturnDate')  THEN CRH.ReturnDate END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='Memo')  THEN CRH.[Memo] END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='ReferenceNo')  THEN ReferenceNo END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='Qty')  THEN Qty END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='UnitPrice')  THEN UnitPrice END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='Amount')  THEN Amount END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='RMAReason')  THEN RMAReason END ASC, 
	    CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceDate')  THEN CRH.InvoiceDate END ASC, 
	    

        
  
        CASE WHEN (@SortOrder=-1 and @SortColumn='RMANumber')  THEN CRH.RMANumber END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='PartNumber')  THEN PartNumber END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='PartDescription')  THEN PartDescription END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerName')  THEN CRH.CustomerName END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='OpenDate')  THEN OpenDate END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='ValidDate')  THEN ValidDate END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='RMAStatus')  THEN RMAStatus END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='Requestedby')  THEN CRH.Requestedby END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='ReturnDate')  THEN CRH.ReturnDate END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='Memo')  THEN CRH.[Memo] END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='ReferenceNo')  THEN ReferenceNo END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='Qty')  THEN Qty END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='UnitPrice')  THEN UnitPrice END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='Amount')  THEN Amount END Desc, 
		CASE WHEN (@SortOrder=-1 and @SortColumn='RMAReason')  THEN RMAReason END Desc, 
        CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceDate')  THEN CRH.InvoiceDate END Desc 
  
        OFFSET @RecordFrom ROWS   
        FETCH NEXT @PageSize ROWS ONLY 
	   END

	   BEGIN
	      
		  ;WITH Result AS(
				SELECT  CRH.[RMAHeaderId] as RMAHeaderId
			,CRH.[RMANumber]
			,CRH.[CustomerId]
			,CRH.[CustomerName]
			,CRH.[CustomerCode]
			,CRH.[ContactInfo]
			,CRH.[OpenDate]
			,CRH.[RMAStatus]
			,CRH.[ValidDate]
			,CRH.Requestedby
			,CRH.[Approvedby]
			,CRH.[ApprovedDate]
			,CRH.[ReturnDate]
			,CRH.[Memo] as Memo
			,CRD.RMADeatilsId
			,CRD.[ReferenceNo]
			,CRD.[isWorkOrder]
			,CRH.[ReferenceId]
			,MSD.LastMSLevel
			,MSD.AllMSlevels
			,CM.CreditMemoHeaderId
			,CRH.[Iswarranty]
			,CRH.[WorkorderNum]
			,CRH.[WorkOrderId]
		
        FROM CustomerRMAHeader CRH WITH(NOLOCK)  
        LEFT JOIN dbo.CustomerRMADeatils CRD WITH(NOLOCK) ON CRD.RMAHeaderId = CRH.RMAHeaderId 
		LEFT JOIN dbo.RMAReason RMAR WITH(NOLOCK) ON CRD.RMAReasonId = RMAR.RMAReasonId 
		INNER JOIN dbo.RMACreditMemoManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = CRH.RMAHeaderId
	    INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON CRH.ManagementStructureId = RMS.EntityStructureId
	    INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId	
		 LEFT JOIN dbo.CreditMemo CM WITH(NOLOCK) ON CM.RMAHeaderId = CRH.RMAHeaderId 

        WHERE ((CRH.MasterCompanyId = @MasterCompanyId) AND (CRH.IsDeleted = @IsDeleted) AND (@StatusID=0 or CRH.RMAStatusId = @StatusID))
			),
			PartCTE AS(  
				Select CRD.RMAHeaderId,(Case When Count(CRD.RMAHeaderId) > 1 Then 'Multiple' ELse A.PartNumber End)  as 'PartNumber',  
				A.PartNumber [PartNumberType] from CustomerRMAHeader CRH WITH (NOLOCK) 
				LEFT JOIN CustomerRMADeatils CRD WITH (NOLOCK) ON CRH.RMAHeaderId =CRD.RMAHeaderId
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(I.partnumber) >0 then ',' ELSE '' END + I.partnumber  
					 FROM CustomerRMADeatils S WITH (NOLOCK)  
					 Left Join ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId  
					 Where S.RMAHeaderId = CRD.RMAHeaderId  
					 AND S.IsActive = 1 AND S.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') PartNumber  
				) A  
				WHERE CRH.MasterCompanyId=@MasterCompanyId AND isnull(CRH.IsDeleted,0)=0
				Group By CRD.RMAHeaderId, A.PartNumber  
				),
				PartDescCTE AS(  
				Select CRD.RMAHeaderId,(Case When Count(CRD.RMAHeaderId) > 1 Then 'Multiple' ELse A.PartDescription End)  as 'PartDescription',  
				A.PartDescription [PartDescriptionType] from CustomerRMAHeader CRH WITH (NOLOCK) 
				LEFT JOIN CustomerRMADeatils CRD WITH (NOLOCK) ON CRH.RMAHeaderId =CRD.RMAHeaderId
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(I.PartDescription) >0 then ',' ELSE '' END + I.PartDescription  
					 FROM CustomerRMADeatils S WITH (NOLOCK)  
					 Left Join ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId  
					 Where S.RMAHeaderId = CRD.RMAHeaderId  
					 AND S.IsActive = 1 AND S.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') PartDescription  
				) A  
				WHERE CRH.MasterCompanyId=@MasterCompanyId AND isnull(CRH.IsDeleted,0)=0
				Group By CRD.RMAHeaderId, A.PartDescription  
				),
			   RMAReasonCTE AS(  
				Select CRD.RMAHeaderId,(Case When Count(CRD.RMAHeaderId) > 1 Then 'Multiple' ELse A.Reason End)  as 'RMAReason',  
				A.Reason [RMAReasonType] from CustomerRMAHeader CRH WITH (NOLOCK) 
				LEFT JOIN CustomerRMADeatils CRD WITH (NOLOCK) ON CRH.RMAHeaderId =CRD.RMAHeaderId
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(I.Reason) >0 then ',' ELSE '' END + I.Reason  
					 FROM CustomerRMADeatils S WITH (NOLOCK) 
					 Left Join RMAReason I WITH (NOLOCK) On S.RMAReasonId=I.RMAReasonId  
					 Where S.RMAHeaderId = CRD.RMAHeaderId  
					 AND S.IsActive = 1 AND S.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') Reason  
				) A  
				WHERE CRH.MasterCompanyId=@MasterCompanyId AND isnull(CRH.IsDeleted,0)=0
				Group By CRD.RMAHeaderId, A.Reason  
				),
				RMAQTYCTE AS(  
				Select CRD.RMAHeaderId,(Case When Count(CRD.RMAHeaderId) > 1 Then 'Multiple' ELse A.Qty End)  as 'Qty',  
				A.Qty [QtyType] from CustomerRMAHeader CRH WITH (NOLOCK) 
				LEFT JOIN CustomerRMADeatils CRD WITH (NOLOCK) ON CRH.RMAHeaderId =CRD.RMAHeaderId
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(CAST(S.Qty AS NVARCHAR(10))) >0 then ',' ELSE '' END + CAST(S.Qty AS NVARCHAR(10))  
					 FROM CustomerRMADeatils S WITH (NOLOCK)  
					 Where S.RMAHeaderId = CRD.RMAHeaderId  
					 AND S.IsActive = 1 AND S.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') Qty  
				) A  
				WHERE CRH.MasterCompanyId=@MasterCompanyId AND isnull(CRH.IsDeleted,0)=0
				Group By CRD.RMAHeaderId, A.Qty  
				),
				RMAUnitPriceCTE AS(  
				Select CRD.RMAHeaderId,(Case When Count(CRD.RMAHeaderId) > 1 Then 'Multiple' ELse A.UnitPrice End)  as 'UnitPrice',  
				A.UnitPrice [UnitPriceType] from CustomerRMAHeader CRH WITH (NOLOCK) 
				LEFT JOIN CustomerRMADeatils CRD WITH (NOLOCK) ON CRH.RMAHeaderId =CRD.RMAHeaderId
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(CAST(S.UnitPrice AS NVARCHAR(10))) >0 then ',' ELSE '' END + CAST(S.UnitPrice AS NVARCHAR(10)) 
					 FROM CustomerRMADeatils S WITH (NOLOCK)  
					 Where S.RMAHeaderId = CRD.RMAHeaderId  
					 AND S.IsActive = 1 AND S.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') UnitPrice  
				) A  
				WHERE CRH.MasterCompanyId=@MasterCompanyId AND isnull(CRH.IsDeleted,0)=0
				Group By CRD.RMAHeaderId, A.UnitPrice  
				),
				RMAUnitAmountCTE AS(  
				Select CRD.RMAHeaderId,(Case When Count(CRD.RMAHeaderId) > 1 Then 'Multiple' ELse A.Amount End)  as 'Amount',  
				A.Amount [AmountType] from CustomerRMAHeader CRH WITH (NOLOCK) 
				LEFT JOIN CustomerRMADeatils CRD WITH (NOLOCK) ON CRH.RMAHeaderId =CRD.RMAHeaderId
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(CAST(S.Amount AS NVARCHAR(10))) >0 then ',' ELSE '' END + CAST(S.Amount AS NVARCHAR(10))  
					 FROM CustomerRMADeatils S WITH (NOLOCK)  
					 Where S.RMAHeaderId = CRD.RMAHeaderId  
					 AND S.IsActive = 1 AND S.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') Amount  
				) A  
				WHERE CRH.MasterCompanyId=@MasterCompanyId AND isnull(CRH.IsDeleted,0)=0
				Group By CRD.RMAHeaderId, A.Amount  
				),
				Results AS( SELECT M.RMAHeaderId,M.[RMANumber],M.[CustomerId],M.[CustomerName],M.[CustomerCode],
				M.[ContactInfo],M.[OpenDate],M.[RMAStatus],M.[ValidDate],M.Requestedby,m.[Approvedby],M.[ApprovedDate],M.[ReturnDate],M.Memo,m.[ReferenceNo],m.[isWorkOrder],
				PT.PartNumber [PartNumber],PD.PartDescription [PartDescription],
				PT.PartNumberType,PD.PartDescriptionType,RC.RMAReason,RC.RMAReasonType,
				QR.Qty,QR.QtyType,UC.UnitPrice,UC.UnitPriceType,
				AC.Amount,AC.AmountType,
				M.LastMSLevel,M.AllMSlevels,M.ReferenceId,M.CreditMemoHeaderId,M.Iswarranty
				,M.[WorkorderNum]
			    ,M.[WorkOrderId]
				from Result M   
					Left Join PartCTE PT On M.RMAHeaderId = PT.RMAHeaderId  
					Left Join PartDescCTE PD on PD.RMAHeaderId = M.RMAHeaderId
					LEFT JOIN RMAReasonCTE RC ON RC.RMAHeaderId=M.RMAHeaderId
					LEFT JOIN RMAQTYCTE QR ON QR.RMAHeaderId=M.RMAHeaderId
					LEFT JOIN RMAUnitPriceCTE UC on UC.RMAHeaderId=M.RMAHeaderId
					LEFT JOIN RMAUnitAmountCTE AC on AC.RMAHeaderId=M.RMAHeaderId
					group by 
					M.RMAHeaderId,M.[RMANumber],M.[CustomerId],M.[CustomerName],M.[CustomerCode],
				M.[ContactInfo],M.[OpenDate],M.[RMAStatus],M.[ValidDate],M.Requestedby,m.[Approvedby],M.[ApprovedDate],M.[ReturnDate],M.Memo,m.[ReferenceNo],m.[isWorkOrder],
				PT.PartNumber,PD.PartDescription,
				PT.PartNumberType,PD.PartDescriptionType,RC.RMAReason,RC.RMAReasonType,
				QR.Qty,QR.QtyType,UC.UnitPrice,UC.UnitPriceType,
				AC.Amount,AC.AmountType,
				M.LastMSLevel,M.AllMSlevels,M.ReferenceId,M.CreditMemoHeaderId,M.Iswarranty,M.[WorkorderNum]
			    ,M.[WorkOrderId]
				),
				ResultCount AS(SELECT COUNT(RMAHeaderId) AS totalItems FROM Results)  
           SELECT * INTO #TempResult from  Results
		   where
		   (  
        (@GlobalFilter <>'' AND (  
        (RMANumber like '%' +@GlobalFilter+'%') OR  
        (CustomerName like '%' +@GlobalFilter+'%') OR  
        (RMAStatus like '%' +@GlobalFilter+'%') OR  
        (Requestedby like '%' +@GlobalFilter+'%') OR  
        (Memo like '%'+@GlobalFilter+'%') OR  
        (PartNumber like '%'+@GlobalFilter+'%') OR  
        (PartDescription like '%' +@GlobalFilter+'%') OR  
		(ReferenceNo like '%' +@GlobalFilter+'%') OR 
		(CAST(Qty AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR	
		(CAST(UnitPrice AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR	
		(CAST(Amount AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR	
        (RMAReason like '%' +@GlobalFilter+'%')  
        ))  
        OR     
        (@GlobalFilter='' AND (IsNull(@RMANumber,'') ='' OR RMANumber like '%' + @RMANumber+'%') AND  
        (IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND  
        (IsNull(@PartDescription,'') ='' OR PartDescription like '%' + @PartDescription+'%') AND  
        (IsNull(@CustomerName,'') ='' OR CustomerName like '%' + @CustomerName+'%') AND  
		(IsNull(@OpenDate,'') ='' OR Cast(OpenDate as Date)=Cast(@OpenDate as date)) AND  
		(IsNull(@ValidDate,'') ='' OR Cast(ValidDate as Date)=Cast(@ValidDate as date)) AND  
	    (IsNull(@ReturnDate,'') ='' OR Cast(ReturnDate as Date)=Cast(@ReturnDate as date)) AND 
        (IsNull(@RMAStatus,'') ='' OR RMAStatus like '%' + @RMAStatus+'%') AND  
        (IsNull(@Memo,'') ='' OR Memo like '%' + @Memo+'%') AND
		(IsNull(@ReferenceNo,'') ='' OR ReferenceNo like '%' + @ReferenceNo+'%') AND  
	    (IsNull(@Qty,'') ='' OR  Qty like '%' + @Qty+'%') AND 
		(IsNull(@UnitPrice,'') ='' OR UnitPrice= @UnitPrice) AND 
		(IsNull(@Amount,'') ='' OR Amount = @Amount) AND 
		(IsNull(@Requestedby,'') ='' OR Requestedby like '%' + @Requestedby+'%') AND 
		(IsNull(@RMAReason,'') ='' OR RMAReason like '%' + @RMAReason+'%')  
        )
		) 
		SELECT @Count = COUNT(RMAHeaderId) from #TempResult     
  
		SELECT *, @Count As NumberOfItems FROM #TempResult 
        ORDER BY    
        CASE WHEN (@SortOrder=1 and @SortColumn='RMANumber')  THEN RMANumber END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='PartNumber')  THEN PartNumber END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='PartDescription')  THEN PartDescription END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='CustomerName')  THEN CustomerName END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='OpenDate')  THEN OpenDate END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='ValidDate')  THEN ValidDate END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='RMAStatus')  THEN RMAStatus END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='Requestedby')  THEN Requestedby END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='ReturnDate')  THEN ReturnDate END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='Memo')  THEN Memo END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='ReferenceNo')  THEN ReferenceNo END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='Qty')  THEN Qty END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='UnitPrice')  THEN UnitPrice END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='Amount')  THEN Amount END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='RMAReason')  THEN RMAReason END ASC, 
	    

        
  
        CASE WHEN (@SortOrder=-1 and @SortColumn='RMANumber')  THEN RMANumber END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='PartNumber')  THEN PartNumber END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='PartDescription')  THEN PartDescription END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerName')  THEN CustomerName END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='OpenDate')  THEN OpenDate END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='ValidDate')  THEN ValidDate END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='RMAStatus')  THEN RMAStatus END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='Requestedby')  THEN Requestedby END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='ReturnDate')  THEN ReturnDate END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='Memo')  THEN Memo END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='ReferenceNo')  THEN ReferenceNo END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='Qty')  THEN Qty END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='UnitPrice')  THEN UnitPrice END Desc,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='Amount')  THEN Amount END Desc, 
		CASE WHEN (@SortOrder=-1 and @SortColumn='RMAReason')  THEN RMAReason END Desc 
  
        OFFSET @RecordFrom ROWS   
        FETCH NEXT @PageSize ROWS ONLY 


	   END

	 

			 

	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_SearchCustomerRMAData' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@RMANumber, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@OpenDate, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@RMAReason , '') AS varchar(100))
			   + '@Parameter10 = ''' + CAST(ISNULL(@RMAStatus , '') AS varchar(100))
			   + '@Parameter11 = ''' + CAST(ISNULL(@ValidDate, '') AS varchar(100))
			   + '@Parameter12 = ''' + CAST(ISNULL(@ReturnDate, '') AS varchar(100))
			  + '@Parameter13 = ''' + CAST(ISNULL(@CustomerName, '') AS varchar(100))
			  + '@Parameter14 = ''' + CAST(ISNULL(@PartNumber, '') AS varchar(100))
			  + '@Parameter15 = ''' + CAST(ISNULL(@PartDescription , '') AS varchar(100))
			  + '@Parameter16 = ''' + CAST(ISNULL(@ReferenceNo , '') AS varchar(100))
			  + '@Parameter17 = ''' + CAST(ISNULL(@Qty , '') AS varchar(100))
			  + '@Parameter18 = ''' + CAST(ISNULL(@UnitPrice , '') AS varchar(100))
			  + '@Parameter19 = ''' + CAST(ISNULL(@Amount , '') AS varchar(100))	
			  + '@Parameter20 = ''' + CAST(ISNULL(@Requestedby , '') AS varchar(100))
			  + '@Parameter21 = ''' + CAST(ISNULL(@LastMSLevel , '') AS varchar(100))
			  + '@Parameter22 = ''' + CAST(ISNULL(@MasterCompanyId  , '') AS varchar(100))
			  + '@Parameter23 = ''' + CAST(ISNULL(@ViewType  , '') AS varchar(100))
			  + '@Parameter24 = ''' + CAST(ISNULL(@EmployeeId, '') AS varchar(100)) 
			  + '@Parameter25 = ''' + CAST(ISNULL(@IsDeleted  , '') AS varchar(100))
			  + '@Parameter26 = ''' + CAST(ISNULL(@Memo, '') AS varchar(100)) 
        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException 
                @DatabaseName           = @DatabaseName
                , @AdhocComments          = @AdhocComments
                , @ProcedureParameters = @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID                    = @ErrorLogID OUTPUT ;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END